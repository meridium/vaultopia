Vaultopia.ArticleSlideShow = function () {

    var $container,
        $imageHolder,
        $next,
        $prev,
        $currentSlide,
        $largeBreakingPoint,
        $mediumBreakingPoint;

    var init = function () {
        $largeBreakingPoint = window.matchMedia("(min-width: 768px)").matches;
        $mediumBreakingPoint = window.matchMedia("(min-width: 400px)").matches;

        $imageHolder = $('#slideshow .slidewrap');
        $container = $('#slideshow');
        $currentSlide = $container.find('li:first-child');

        $currentSlide.addClass('selected');
        initControls();
        registerEvents();
        changeImage();

        $(window).resize(function () {
            clearTimeout(this.id);
            this.id = setTimeout(changeImage, 2000);
        });
    };

    var registerEvents = function () {
        $next.click(function (e) {
            e.preventDefault();
            if ($currentSlide.next().length == 0) {
                $currentSlide = $container.find('li:first-child');
            }
            else {
                $currentSlide = $currentSlide.next();
            }
            changeImage();
        });

        $prev.click(function (e) {
            e.preventDefault();
            if ($currentSlide.prev().length == 0) {
                $currentSlide = $container.find('li:last-child');
            }
            else {
                $currentSlide = $currentSlide.prev();
            }
            changeImage();
        });

        $container.find('img').click(function (e) {
            e.preventDefault();
            $currentSlide = $(this).closest('li');
            changeImage();
        });
    };

    var pickImage = function() {
        if ($container.find('img').is(':animated')) {
            return;
        }
        $container.find('li').removeClass('selected');
        $currentSlide.addClass('selected');

        var mobileUrl = $currentSlide.attr('data-mobile-url');
        var mediumUrl = $currentSlide.attr('data-medium-url');
        var largeUrl = $currentSlide.attr('data-large-url');

        if (window.matchMedia("screen and (min-width: 768px)").matches) {
            return $('<img src="' + largeUrl + '" alt="" />');
        }
        else if (window.matchMedia("screen and (max-width: 768px) and (min-width: 400px)").matches) {
            return $('<img src="' + mediumUrl + '" alt="" />');
        }
        else {
            return $('<img src="' + mobileUrl + '" alt="" />');
        } 
    };

    var changeImage = function () {
        var $image = pickImage();
        $image.imagesLoaded(function () {
            $imageHolder.children('img').before($image);

            /*$image.next().animate({ left: '-500px', opacity: '0' }, 400, function() {
                $(this).remove();
            });*/

            $image.next().fadeOut(400, function () {
                $(this).remove();
            });
        });
    };

    var initControls = function () {
        $prev = $('<a href="#" class="prev icon">Previous</a>');
        $imageHolder.prepend($prev);

        $next = $('<a href="#" class="next icon">Next</a>');
        $imageHolder.append($next);
    };

    return {
        init: init
    };

}()