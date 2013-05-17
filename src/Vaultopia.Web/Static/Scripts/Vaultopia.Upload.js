Vaultopia.Upload = function() {
    var $container,
        imageId;

    var registerEvents = function() {
        $container.find('form').submit(function(e) {
            e.preventDefault();

            if (imageId == undefined) {
                return false;
            }

            $container.find('.button').
                closeDialog(e);

            var model = {
                Id: imageId,
                Title: $container.find('input[name="Title"]').val(),
                Description: $container.find('textarea[name="Description"]').val()
            };

            $.ajax({
                type: 'POST',
                data: JSON.stringify(model),
                url: '/gallery/save',
                contentType: 'application/json',
                success: function(data) {
                    $(document).trigger('FileSaved', data);
                }
            });
        });

        $(document).on('click', '#remove-image-anchor', function(e) {
            e.preventDefault();
            $container.find('.remove').remove();
            $container.find('img').remove();
            $container.find("#droparea").show();
            $container.find(".droptext").show();
            imageId = undefined;
        });

        $container.find('.close').click(closeDialog);

        $(document).keydown(function(e) {
            if (e.keyCode == 27) {
                closeDialog(e);
            }
        });

        $container.find("#droparea").bind('dragenter, dragover', function(e) {
            e.preventDefault();
            $(this).addClass('hover');
        });

        $container.find("#droparea").bind('dragleave', function (e) {
            
            $(this).removeClass('hover');
        });



        $container.find("#droparea").bind('drop', function(e) {
            e.preventDefault();
  
            $container.find('p').hide();
            $container.find('progress').show();

            uploadFile(e.originalEvent.dataTransfer.files[0]);
        });

    };


    function uploadFile(file) {

        var formData = new FormData();
        formData.append('file', file);

        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/Gallery/UploadFile');
        xhr.onload = function() {
            $container.find('progress').val(100);
        };

        xhr.upload.onprogress = function(e) {
            if (e.lengthComputable) {
                var progress = (e.loaded / e.total) * 100;
                $container.find('progress').val(progress);
                console.log(progress);
            }
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState == 4) {
                displayThumbnail(xhr.responseText);
            }
        };

        xhr.send(formData);

    }

    var displayThumbnail = function (response) {

        var $droparea = $container.find("#droparea");

        response = JSON.parse(response);

        setTimeout(function () {
            $droparea.hide();

            var $image = $('<img src="' + response.Url + '" alt="" width="111" height="111" />');

            $droparea.after($image);
            $image.after('<p class="remove"><a href="" id="remove-image-anchor">Remove image</a></p>');

            imageId = response.Id;
        }, 1000);
    };

    var closeDialog = function(e) {
        e.preventDefault();
        $('.overlay').fadeOut(100, function () {
            $(this).remove();
        });
    };

    var initDrop = function() {

        var $droparea = $container.find("#droparea");

        /*$droparea.html5Uploader({
            name: "file",
            postUrl: "/Gallery/UploadFile",
            
            onClientLoadStart: function (e, file) {
                console.log(file);
                $container.find('p').hide();
            },
            onClientLoad: function (e, file) {
                
            },
            onServerLoadStart: function (e, file) {

                $container.find('progress').show();
            },
            onServerProgress: function (e, file) {
                var progress = (e.loaded / e.total) * 100;

                
                $container.find('progress').val(progress);

            },
            onServerLoad: function (e, file) {
                $container.find('progress').delay(1000).fadeOut();
            },
            onSuccess: function (e, file, response) {
                
                response = JSON.parse(response);

                setTimeout(function() {
                    $droparea.hide();

                    var $image = $('<img src="' + response.Url + '" alt="" width="111" height="111" />');

                    $droparea.after($image);
                    $image.after('<p class="remove"><a href="" id="remove-image-anchor">Remove image</a></p>');

                    imageId = response.Id;
                }, 1000);


            },
            onServerError: function (e, file) {
                alert("Could not upload file: " + file.name);
            }
        });*/
    };

   
    

    var init = function () {
        $.get("upload", function (data) {
            
            $('body').prepend(data);
            
            $container = $('#upload');
            $container.find('progress').hide();

            registerEvents();


            initDrop();

        });
    };

    return {
        init: init,
    };
}()