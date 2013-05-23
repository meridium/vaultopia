Vaultopia.ArticleSlideShow = function () {

    var $container,
        $next,
        $prev,
        $currentSlide;

    var init = function () {

        $container = $('#slideshow');
        $currentSlide = $container.find('li:first-child');

        $currentSlide.addClass('selected');

        initControls();
        registerEvents();
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

        $container.find('img').click(function(e) {
            e.preventDefault();
            $currentSlide = $(this).closest('li');
            changeImage();
        });
    };

    var changeImage = function () {
        if ($container.find('img').is(':animated')) {
            return;
        }

        $container.find('li').removeClass('selected');
        $currentSlide.addClass('selected');
        
        var url = $currentSlide.attr('data-large-url');

        var $image = $('<img src="' + url + '" alt="" />');

        $image.imagesLoaded(function () {
            $container.children('img').before($image);

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
        $container.prepend($prev);

        $next = $('<a href="#" class="next icon">Next</a>');
        $container.append($next);
    };

    return {
        init: init
    };

}()