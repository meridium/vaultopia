Vaultopia.SlideShow = function () {

    var $container,
        $next,
        $prev,
        _index = 0,
        _images;

    var init = function (slides) {

        _images = slides.images;
        $container = $('#slide');

        if (_images.length == 0) {
            return;
        }

        initControls();
        registerEvents();
    };

    var registerEvents = function () {
        $next.click(function (e) {
            e.preventDefault();
            updateIndex(1);
            changeImage();
        });

        $prev.click(function (e) {
            e.preventDefault();
            updateIndex(-1);
            changeImage();
        });
    };

    var updateIndex = function (step) {
        if (_index + step + 1 > _images.length) {
            _index = 0;
            return;
        }
        if (_index + step < 0) {
            _index = _images.length - 1;
            return;
        }
        _index = _index + step;
    };

    var changeImage = function () {
        if ($container.find('.slide').is(':animated')) {
            return;
        }

        var $image = $('<div class="slide" style="background-image:url(' + _images[_index] + ')"></div>');

        $image.imagesLoaded(function () {
            $container.find('.slide').before($image);

            $image.next().fadeOut(500, function () {
                $(this).remove();
            });
        });
    };

    var initControls = function () {
        $prev = $('<a href="#" class="prev icon">Previous</a>');
        $container.find('div > div').append($prev);

        $next = $('<a href="#" class="next icon">Next</a>');
        $container.find('div > div').append($next);
    };

    return {
        init: init
    };

}()