<?php
// admin/api/_translate_lib.php
//
// Groq-backed auto-translation for question Hindi (_hi) fields.
//
// How it works:
//  • Admin pastes a Groq API key in Admin → App Settings (groq_api_key).
//  • When the app fetches questions (questions.php / weekly_challenge.php /
//    daily_practice.php), any row whose `question_text_hi` is empty is sent to
//    Groq for translation, the result is written back into the DB (cached), and
//    the row is filled in-place so the SAME response already carries Hindi.
//  • Next time that question is served, it's instant (already cached).
//
// Safe by design: no Groq key → no-op. Any network/parse error → no-op
// (the app still works, just shows English until a key/translation exists).

if (!function_exists('tunnl_get_setting')) {
    /** Read a value from the app_settings table (cached for the request). */
    function tunnl_get_setting(PDO $pdo, string $key, string $default = ''): string {
        static $cache = null;
        if ($cache === null) {
            $cache = [];
            try {
                $rows = $pdo->query("SELECT setting_key, setting_value FROM app_settings")
                            ->fetchAll(PDO::FETCH_ASSOC);
                foreach ($rows as $r) { $cache[$r['setting_key']] = $r['setting_value']; }
            } catch (Throwable $e) { $cache = []; }
        }
        return (isset($cache[$key]) && $cache[$key] !== '') ? $cache[$key] : $default;
    }
}

if (!function_exists('tunnl_fill_hindi')) {
    /**
     * Ensure each question row has Hindi (_hi) fields. Rows are passed by
     * reference and mutated in-place. Missing translations are generated via
     * Groq and persisted to the `questions` table.
     *
     * Each row must contain: id, question_text, option_a..d, explanation,
     * and (optionally) the *_hi columns.
     */
    function tunnl_fill_hindi(PDO $pdo, array &$rows): void {
        if (empty($rows)) return;
        if (!function_exists('curl_init')) return;

        $apiKey = tunnl_get_setting($pdo, 'groq_api_key', '');
        if ($apiKey === '') return;

        $model = tunnl_get_setting($pdo, 'groq_model', 'llama-3.3-70b-versatile');

        // Which rows still need a Hindi question?
        $need = [];
        foreach ($rows as $i => $r) {
            if (trim((string)($r['question_text_hi'] ?? '')) === '') {
                $need[] = $i;
            }
        }
        if (empty($need)) return;

        $upd = $pdo->prepare("
            UPDATE questions SET
              question_text_hi = ?, option_a_hi = ?, option_b_hi = ?,
              option_c_hi = ?, option_d_hi = ?, explanation_hi = ?
            WHERE id = ?
        ");

        // Translate in small batches to keep each request fast & reliable.
        $batchSize = 15;
        for ($b = 0; $b < count($need); $b += $batchSize) {
            $slice   = array_slice($need, $b, $batchSize);
            $payload = [];
            foreach ($slice as $i) {
                $r = $rows[$i];
                $payload[] = [
                    'id'          => (int)$r['id'],
                    'question'    => (string)($r['question_text'] ?? ''),
                    'a'           => (string)($r['option_a'] ?? ''),
                    'b'           => (string)($r['option_b'] ?? ''),
                    'c'           => (string)($r['option_c'] ?? ''),
                    'd'           => (string)($r['option_d'] ?? ''),
                    'explanation' => (string)($r['explanation'] ?? ''),
                ];
            }

            $out = tunnl_groq_translate($apiKey, $model, $payload);
            if (!$out) continue;

            $byId = [];
            foreach ($out as $t) {
                if (isset($t['id'])) $byId[(int)$t['id']] = $t;
            }

            foreach ($slice as $i) {
                $id = (int)$rows[$i]['id'];
                if (!isset($byId[$id])) continue;
                $t  = $byId[$id];
                $qh = trim((string)($t['question'] ?? ''));
                if ($qh === '') continue;

                $ah = (string)($t['a'] ?? '');
                $bh = (string)($t['b'] ?? '');
                $ch = (string)($t['c'] ?? '');
                $dh = (string)($t['d'] ?? '');
                $eh = (string)($t['explanation'] ?? '');

                try { $upd->execute([$qh, $ah, $bh, $ch, $dh, $eh, $id]); }
                catch (Throwable $e) { /* ignore, still return live value */ }

                $rows[$i]['question_text_hi'] = $qh;
                $rows[$i]['option_a_hi']      = $ah;
                $rows[$i]['option_b_hi']      = $bh;
                $rows[$i]['option_c_hi']      = $ch;
                $rows[$i]['option_d_hi']      = $dh;
                $rows[$i]['explanation_hi']   = $eh;
            }
        }
    }
}

if (!function_exists('tunnl_groq_translate')) {
    /**
     * Calls Groq's OpenAI-compatible chat-completions endpoint to translate a
     * batch of items to Hindi. Returns an array of
     * {id, question, a, b, c, d, explanation} or null on any failure.
     */
    function tunnl_groq_translate(string $apiKey, string $model, array $items): ?array {
        $sys = "You are a precise translator for an Indian competitive-exam math quiz app. "
             . "Translate each item's English text into natural, simple Hindi (Devanagari script). "
             . "STRICT RULES: keep ALL numbers, math symbols (+,-,×,÷,=,%,√,etc.), variables, "
             . "units, currency and the option letters EXACTLY as in the source. "
             . "Do NOT solve, simplify or change any math. Keep translations short. "
             . "If a field is an empty string, return it as an empty string. "
             . "Return ONLY minified JSON of the form "
             . "{\"items\":[{\"id\":<int>,\"question\":\"..\",\"a\":\"..\",\"b\":\"..\",\"c\":\"..\",\"d\":\"..\",\"explanation\":\"..\"}]} "
             . "with one object per input item, preserving the same id.";

        $userMsg = json_encode(['items' => $items], JSON_UNESCAPED_UNICODE);

        $body = json_encode([
            'model'           => $model,
            'temperature'     => 0.2,
            'max_tokens'      => 8000,
            'response_format' => ['type' => 'json_object'],
            'messages'        => [
                ['role' => 'system', 'content' => $sys],
                ['role' => 'user',   'content' => $userMsg],
            ],
        ], JSON_UNESCAPED_UNICODE);

        $ch = curl_init('https://api.groq.com/openai/v1/chat/completions');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_TIMEOUT        => 45,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $apiKey,
            ],
            CURLOPT_POSTFIELDS     => $body,
        ]);
        $resp = curl_exec($ch);
        $http = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($resp === false || $http < 200 || $http >= 300) return null;

        $json    = json_decode($resp, true);
        $content = $json['choices'][0]['message']['content'] ?? '';
        if ($content === '') return null;

        $parsed = json_decode($content, true);
        if (!is_array($parsed)) return null;

        $items = $parsed['items'] ?? $parsed;
        return is_array($items) ? $items : null;
    }
}
