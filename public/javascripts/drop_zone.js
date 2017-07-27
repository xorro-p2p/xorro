function handleFileSelect(evt) {
  var files = evt.target.files; // FileList object

  // Loop through the FileList and render image files as thumbnails.
  for (var i = 0, f; f = files[i]; i++) {
    var reader = new FileReader();
    
    reader.onload = (function(theFile) {
      return function(e) {
        $.ajax({
          method: "POST",
          url: '/save_to_uploads',
          data: { name: theFile.name, data: e.target.result },
        });
      };
    })(f);
    reader.readAsDataURL(f);
  }
}

// function handleDragOver(evt) {
//   evt.stopPropagation();
//   evt.preventDefault();
//   evt.dataTransfer.dropEffect = 'copy'; // Explicitly show this is a copy.
// }

// var dropZone = document.getElementById('drop_zone');
// dropZone.addEventListener('dragover', handleDragOver, false);
// dropZone.addEventListener('drop', handleFileSelect, false);
document.getElementById('files').addEventListener('change', handleFileSelect, false);