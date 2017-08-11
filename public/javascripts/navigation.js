var path = window.location.pathname
if (!path.includes("debug")) {
  $("#sidenav > ul > li a[href='" + path + "']").parent().addClass('active');
}
