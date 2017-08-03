var $form = $('.box');
var $fileInput = $('.box_file');
var droppedFiles = false;

$form.on('drag dragstart dragend dragover dragenter dragleave drop', function(e) {
  e.preventDefault();
  e.stopPropagation();
})
.on('dragover dragenter', function() {
  $form.addClass('is-dragover');
})
.on('dragleave dragend drop', function() {
  $form.removeClass('is-dragover');
})
.on('drop', function(e) {
  droppedFiles = e.originalEvent.dataTransfer.files;
  $form.trigger('submit');
});

$fileInput.change(function (e) {
  droppedFiles = $fileInput[0].files
  $form.trigger('submit');
});

$form.on('submit', function(e) {
  if ($form.hasClass('is-uploading')) return false;

  $form.addClass('is-uploading').removeClass('is-error');

  e.preventDefault();

  for (var i = 0, f; f = droppedFiles[i]; i++) {
    var reader = new FileReader();

    reader.onload = (function(theFile) {
      return function(e) {
        $.ajax({
          type: $form.attr('method'),
          url: $form.attr('action'),
          data: { name: theFile.name, data: e.target.result },
          complete: function() {
            $form.removeClass('is-uploading');
          },
          success: function(data) {
            $form.addClass('is-success');
          },
          error: function() {
            // Log the error, show an alert, whatever works for you
          }
        });
      };
    })(f);
    reader.readAsDataURL(f);
  }
});