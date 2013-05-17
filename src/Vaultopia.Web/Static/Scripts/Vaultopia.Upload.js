Vaultopia.Upload = function () {
    var $container,
        imageId;

    var registerEvents = function() {
        $container.find('form').submit(function(e) {
            e.preventDefault();
            
            $('.overlay').remove();

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


        $(document).on('click', 'remove-image-anchor', function() {

        });


    };

    var initDrop = function() {

        var $droparea = $container.find("#droparea");

        

        $droparea.html5Uploader({
            name: "file",
            postUrl: "/Gallery/UploadFile",
            
            onClientLoadStart: function (e, file) {
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
                $container.find('progress').fadeOut();
            },
            onSuccess: function (e, file, response) {
                
                response = JSON.parse(response);

                $droparea.hide();

                var $image = $('<img src="' + response.Url + '" alt="" width="111" height="111" />');

                $droparea.after($image);
                $image.after('<p><a href="" id="remove-image-anchor">Remove image</a></p>');

                imageId = response.Id;



            },
            onServerError: function (e, file) {
                alert("Could not upload file: " + file.name);
            }
        });
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