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
                    });

                }
            });
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