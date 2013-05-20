var Vaultopia = {
    Home: {},
};

$(document).ready(function () {
    $('#toggle-nav').click(function(e) {
        e.preventDefault();

        if ($('#global-nav').is(':visible')) {
            $('#global-nav').hide();
            $(this).removeClass('open');
        } else {
            $('#global-nav').show();
            $(this).addClass('open');
        }
    });

    $('#gallery ul').imagesLoaded(function() {
        $('#gallery ul').masonry({
            itemSelector: 'li'
        });
    });

    
    $('#upload-action').click(function (e) {
        e.preventDefault();
        Vaultopia.Upload.init();
    });

    Vaultopia.Gallery.init();


});