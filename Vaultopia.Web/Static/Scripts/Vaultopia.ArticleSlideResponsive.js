$(document).ready(function () {
    var $container = $("#slideshow ul");
    var $imageButton = $(".imagedrop");

    $imageButton.click(function () {
        $container.slideToggle();
    });
    $(window).resize(function () {
        if ($(window).width() < 384) {
            $container.css("display", "none");
        }
        else {
            $container.css("display", "inline");
        }
    });
});


//$(document).ready(function () {
//    Vaultopia.ArticleSlideResponsive = function () {
//        var $container = $("#slideshow ul");
//        var $imageButton = $(".imagedrop");

//        $imageButton.click(function () {
//            $container.slideToggle();
//        });

//        var hideImageUrls = function () {
//            if (window.matchMedia("screen and (max-width: 400px)").matches) {
//                $container.css("display", "none");
//            }
//            else {
//                $container.css("display", "inline");
//            }
//        };

//        $(window).resize(function () {
//            clearTimeout(this.id);
//            this.id = setTimeout(hideImageUrls, 2000);
//        });
//    }
//});