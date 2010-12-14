function reloadProjects(){
  $.ajax({method: 'get',url : '/projects.js'});
}

