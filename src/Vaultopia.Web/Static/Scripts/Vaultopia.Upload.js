Vaultopia.Upload = function() {
    var $container,
        imageId;

    var init = function () {
        $.get("upload", function (data) {
            //Get and show dialog
            $('body').prepend(data);

            $container = $('#upload');
            $container.find('progress').hide();

            registerEvents();
        });
    };

    var registerEvents = function() {

        //Save metadata and set image as organized and ready to use.
        $container.find('form').submit(save);

        //Clear uploaded image.
        $(document).on('click', '#remove-image-anchor', clearImage);

        //Close dialog.
        $container.find('.close').click(closeDialog);

        //Close dialog when esc is hit.
        $(document).keydown(function(e) {
            if (e.keyCode == 27) {
                closeDialog(e);
            }
        });

        //Display hover when image is dragged into droparea.
        $container.find("#droparea").bind('dragenter, dragover', function(e) {
            e.preventDefault();
            $(this).addClass('hover');
        });

        //Remove hover when leaving droparea.
        $container.find("#droparea").bind('dragleave', function (e) {
            $(this).removeClass('hover');
        });

        //Handle drop and upload file.
        $container.find("#droparea").bind('drop', function(e) {
            e.preventDefault();
  
            $container.find('p').hide();
            $container.find('progress').show();

            uploadFile(e.originalEvent.dataTransfer.files[0]);

        });
    };

    var clearImage = function(e) {
        e.preventDefault();
        $container.find('.remove').remove();
        $container.find('img').remove();
        $container.find("#droparea").show();
        $container.find(".droptext").show();
        imageId = undefined;
        $container.find('.button').fadeTo(100, .5);
    };

    var save = function(e) {
        e.preventDefault();

        if (imageId === undefined) {
            return false;
        }
    
        closeDialog(e);

        var model = {
            Id: imageId,
            Title: $container.find('input[name="Title"]').val(),
            Description: $container.find('textarea[name="Description"]').val()
        };

        $.ajax({
            type: 'POST',
            data: JSON.stringify(model),
            url: '/gallery/save/',
            contentType: 'application/json',
            success: function (data) {
                $(document).trigger('FileSaved', data);
            }
        });
    };

    var uploadFile = function (file) {

        var formData = new FormData();
        formData.append('file', file);

        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/Gallery/UploadFile/');

        xhr.upload.onprogress = function(e) {
            if (e.lengthComputable) {
                var progress = (e.loaded / e.total) * 100;
                $container.find('progress').val(progress);
            }
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState == 4) {
                displayThumbnail(xhr.responseText);
            }
        };

        xhr.send(formData);

    };

    var displayThumbnail = function (response) {

        var $droparea = $container.find("#droparea");

        response = JSON.parse(response);
        var $image = $('<img src="' + response.Url + '" alt="" width="111" height="111" />');
        $image.hide();

        $container.find('progress').hide();
        $droparea.fadeOut(100, function() {
            $image.imagesLoaded(function () {
                $droparea.after($image);
                $image.after('<p class="remove"><a href="" id="remove-image-anchor">Remove image</a></p>');
                $image.fadeIn(100);
                $container.find('.button').fadeTo(100, 1);
            });
        });
            
        imageId = response.Id;
    };

    var closeDialog = function(e) {
        e.preventDefault();
        $('.overlay').fadeOut(100, function () {
            $(this).remove();
        });
    };

    return {
        init: init,
    };
}()