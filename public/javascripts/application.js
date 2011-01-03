function setAjaxReload(url){
  $(document).ready(function(){setInterval('ajaxReload("' + url + '")', 5000);});
}
function ajaxReload(url){
  if($("#ajax-reload").html() == 'true'){
    $.ajax({method: 'get', url : url});
  }
}