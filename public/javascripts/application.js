function reloadProjects(){
  $.ajax({method: 'get',url : '/projects.js'});
}

function reloadBuilds(project_id){
  $.ajax({method: 'get',url : '/projects/' + project_id + '.js'});
}
