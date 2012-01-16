function setAjaxReload(url){
  $(document).ready(function(){setInterval('ajaxReload("' + url + '")', 5000);});
}
function ajaxReload(url){
  if($("#ajax-reload").html() == 'true'){
    $.ajax({method: 'get', url : url});
  }
}

jQuery('ol.list-with-status div.command_box').click(function() {
  //console.log($('pre.step', this));
  console.log ('foo');
});
