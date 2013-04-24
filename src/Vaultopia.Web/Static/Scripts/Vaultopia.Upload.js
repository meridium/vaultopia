Vaultopia.Upload = function () {
    var $container;


    var openDialog = function () {
        $.get("upload", function (data) {
            $('body').prepend(data);
        });
    };

    var init = function () {
        $container = $('#upload');
        openDialog();
    };

    return {
        init: init
    };
}()