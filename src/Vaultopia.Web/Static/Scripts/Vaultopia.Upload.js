Vaultopia.Upload = function () {
    var $container;

    var registerEvents = function() {
        $container.find('form').submit(function(e) {
            e.preventDefault();
            $.ajax({
                type: "POST",
                data: { foo: 'bar' },
                url: "save",
                success: function(data) {
                    alert(data);
                }
            });
        });
    };

    var initDrop = function() {

        var $droparea = $container.find("#droparea");

        $droparea.on('drop', function (e) {
            e.preventDefault();
            console.log(e.originalEvent.dataTransfer.files.length);
        });
        $droparea.on('dragover', function (e) {
            e.preventDefault();

            $droparea.addClass('over');
        });
        $droparea.on('dragleave', function (e) {
            e.preventDefault();
            $droparea.removeClass('over');
        });

    };
    
    var init = function () {
        $.get("upload", function (data) {
            
            $('body').prepend(data);
            
            $container = $('#upload');
            registerEvents();


            initDrop();

        });
    };

    return {
        init: init,
    };
}()