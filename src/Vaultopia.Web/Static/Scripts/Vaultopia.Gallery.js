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
                        if ($images.find('li').length <= 32) {
                            $('#gallery-paging-action').remove();
                        }

                        $('#gallery ul').append($images.find('li:not(:last-child)')).masonry('reload');
                        $('#gallery-paging-action').removeClass('loading');
  
                        registerHoverEvents();
                        $container.find('.image').fancybox();
                    });
                }
            });




        });
        

        $(document).bind('FileSaved', function (e, html) {

            //Don't know why I need to wrap my li...
            var $html = $('<ul>' + html + '</ul>');;
            
            $html.imagesLoaded(function () {
                $container.find('ul').prepend($html.find('li')).masonry('reload');
                registerHoverEvents();
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
                        
                       
                        
                        $section.removeClass('loading').find('span').after($html);
                      



                        initMap($html.find('#map').attr('data-map-lat'), $html.find('#map').attr('data-map-lng'));

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
            $(this).find('a img').fadeTo(100, .5);
            $(this).find('.enlarge').fadeIn(100);
            $(this).find('.metadata-anchor').fadeIn(100);
        }, function () {
            $(this).removeClass('hover');
            $(this).find('a img').fadeTo(100, 1);
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

    var initMap = function (lat, lng) {
        console.log(lat);
        console.log(lng);

        if (lat == "" || lng == "") {
            return;
        }

        var myLatlng = new window.google.maps.LatLng(lat, lng);
        var mapOptions = {
            disableDefaultUI: true,
            zoom: 6,
            center: myLatlng,
            mapTypeId: window.google.maps.MapTypeId.ROADMAP
        };
        var map = new window.google.maps.Map(document.getElementById('map'), mapOptions);
            
        var icon = new google.maps.MarkerImage("/static/images/marker.png", null, null, null, new google.maps.Size(18,25));
            
        var marker = new window.google.maps.Marker({
            position: myLatlng,
            map: map,
            icon: icon
        });
    };

    var init = function () {
        $container = $('#gallery');
        registerEvents();

        $container.find('.image').fancybox();

    };

    return {
        init: init,
    };
}()