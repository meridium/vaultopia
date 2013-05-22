var Vaultopia = {};

$(document).ready(function () {

    //Responsive navigation
    $('#toggle-nav').click(function (e) {
        e.preventDefault();
        if ($('#global-nav').is(':visible')) {
            $('#global-nav').hide();
            $(this).removeClass('open');
        } else {
            $('#global-nav').show();
            $(this).addClass('open');
        }
    });

});