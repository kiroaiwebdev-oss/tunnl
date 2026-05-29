  </div><!-- end page-content -->
</div><!-- end main-content -->

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
// Sidebar toggle
function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
  document.getElementById('overlay').classList.toggle('open');
}

// Live clock
function updateTime() {
  const now = new Date();
  document.getElementById('liveTime').textContent =
    now.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
}
updateTime();
setInterval(updateTime, 1000);

// Auto-hide alerts
document.querySelectorAll('.alert').forEach(el => {
  setTimeout(() => el.style.display = 'none', 4000);
});
</script>
</body>
</html>