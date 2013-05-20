Vaultopia.Home.SlideShow = function () {

    var $container,
        $next,
        $prev,
        _index = 0,
        _images;

    var init = function (slides) {

        _images = slides.images;
        $container = $('#push');

        if (_images.length == 0) {
            return;
        }

        initControls();
        registerEvents();
    };

    var registerEvents = function() {
        $next.click(function(e) {
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

    var updateIndex = function(step) {
        _index = _index + step;
    };

    var changeImage = function() {
        var $image = $('<div class="slide" style="background-image:url(' + _images[_index].url + ')"></div>');

        $image.imagesLoaded(function () {
            $container.find('.slide').before($image);

            $image.next().fadeOut(500, function () {
                $(this).remove();
            });
        });
    };

    var initControls = function() {
        $prev = $('<a href="#" class="prev">Previous</a>');
        $container.find('div > div').append($prev);

        $next = $('<a href="#" class="next">Next</a>');
        $container.find('div > div').append($next);
    };

    return {
        init: init
    };
    
}()