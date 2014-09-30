$(document).ready(function () {
    var $container = $("#slideshow ul");
    var $imageButton = $(".imagedrop");

    $imageButton.click(function () {
        $container.slideToggle();
    });
    //Display imagedrop button in mobile resolution
    $(window).resize(function () {
        if ($(window).width() < 384) {
            $container.css("display", "none");
        }
        else {
            $container.css("display", "inline");
        }
    });
});