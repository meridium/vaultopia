Vaultopia.Gallery = function () {
    var $container,
        skip = 1;

    var registerEvents = function() {
        $('#gallery-paging-action').click(function(e) {
            e.preventDefault();
            $.ajax({
                url: "Load",
                data: { skip: skip },
                beforeSend: function() {
                    $('#gallery-paging-action').addClass('loading');
                },
                success: function(data) {
                    skip += 1;

                    var $images = $('<ul>' + data + '</ul>');

                    $images.imagesLoaded(function() {
                        $('#gallery ul').append($images.find('li:not(:last-child)')).masonry('reload');
                        $('#gallery-paging-action').removeClass('loading');
                        
                        if ($images.find('li').length <= 16) {
                            $('#gallery-paging-action').remove();
                        }
                        
                        registerHoverEvents();
                    });
                }
            });
        });
       
        $(document).on('click', '#gallery .metadata-anchor', function(e) {
            e.preventDefault();
            e.stopPropagation();

            var $that = $(this);
            var $section;

            $('.metadata-anchor').not(this).fadeOut(100);

            if ($that.closest('li').find('#metadata').length > 0) {
                $('#metadata').fadeOut(100, function () { $(this).remove(); });
                return;
            } else {
                $('#metadata').fadeOut(100, function () { $(this).remove(); });
                $.ajax({
                    url: 'ShowMetaData',
                    data: { imageId: $that.closest('li').attr('data-image-id') },
                    beforeSend: function() {
                        $section = $('<section id="metadata" class="loading">' +
                                       '<span class="arrow sprite"></span>' +
                                     '</section>');
                        $that.after($section);
                    },
                    success: function (html) {
                        var $html = $(html);
                        
                        $html.hide();
                        
                        $section.removeClass('loading').find('span').after($html);
                        $html.fadeIn(100);

                        

                    }
                });
            }
        });

        $(document).on('click', '#metadata', function(e) {
            e.stopPropagation();
        });
        $(document).on('click', 'body', function(e) {
            removeMetaDataOverlay();
        });

        registerHoverEvents();

    };

    var registerHoverEvents = function() {
        $('#gallery li').hoverIntent(function () {
            $(this).addClass('hover');
            $(this).find('img').fadeTo(100, .3);
            $(this).find('.enlarge').fadeIn(100);
            $(this).find('.metadata-anchor').fadeIn(100);
        }, function () {
            $(this).removeClass('hover');
            $(this).find('img').fadeTo(100, 1);
            $(this).find('.enlarge').fadeOut(100);
            if ($(this).find('#metadata').length == 0) {
                $(this).find('.metadata-anchor').fadeOut(100);
            }
        });
    };

    var removeMetaDataOverlay = function() {
        $('.metadata-anchor').fadeOut(100);
        $('#metadata').fadeOut(100, function () {
            $(this).remove();
        });
    };

    var init = function () {
        $container = $('#gallery');
        registerEvents();


    };

    return {
        init: init,
    };
}()