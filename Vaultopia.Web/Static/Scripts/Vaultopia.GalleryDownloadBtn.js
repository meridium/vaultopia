Vaultopia.GalleryDownloadBtn = function() {

    var img;
    var id;
    var originalWidth;
    var imageSettings;

    var init = function () {
        createData();
        showButtons();
        addDownload();
    };

    //Sends id for choosen image to controller method
    var getData = function() {
        var myData;
        $.ajax({
            async: false,
            url: 'Download',
            type: 'GET',
            datatype: 'json',
            data: ("id=" + id),
            success: function(response) {
                myData = response;
            }
        });
        return myData;
    };

    //Get id and width of current picture
    var createData = function() {
        $(".image").click(function() {
            id = $(this).parent("li").attr("data-image-id");
            originalWidth = parseInt($(this).parent("li").attr("data-image-width"));
        });
    };

    //Add downloadbutton to interface and save original image src, also set returnvalue of getData to variable imageSettings
    var addDownload = function() {
        $(".image").fancybox({
            beforeShow: function() {
                this.title += '<div id="displayformats" class="button downloadbtn">Download</div>';
            },
            afterShow: function () {
                
                img = this.href;
                imageSettings = JSON.parse(getData());
            },
            helpers: {
                title: {
                    type: 'inside'
                }
            }
        });
    };

    //Add buttons for each resolution
    var addButtons = function() {
        var buttons = { jpg: ["<li>JPG</li>"], png: ["<li>PNG</li>"], gif: ["<li>GIF</li>"] };
        var format;
        for (var i = 0; i < imageSettings.length;) {
            if (originalWidth > imageSettings[i].Width || originalWidth === imageSettings[i].Width) {
                format = imageSettings[i].Format;
                var listItem = '<li>' + '<a href="' + imageSettings[i].Url + '">' + imageSettings[i].LinkName + ' (' + imageSettings[i].Width + 'x' + imageSettings[i].Height + ')</a></li>';
                switch (format) {
                case "Jpeg":
                    buttons.jpg.push(listItem);
                    break;
                case "Png":
                    buttons.png.push(listItem);
                    break;
                case "Gif":
                    buttons.gif.push(listItem);
                    break;
                default:
                    break;
                }
            }
            i += 1;
        }
        return buttons;
    };

    //Print interface for download
    var showButtons = function() {
        $(document).on('click', '#displayformats', function() {
            $.fancybox({
                content: '<div class="formatbox">' +
                    '<img class="formatimg" src="' + img + '" alt="" />' +
                    '<div class="downloadformats">' +
                    '<ul class="formatitems">' + addButtons().jpg.join("") + '</ul>' +
                    '<ul class="formatitems">' + addButtons().png.join("") + '</ul>' +
                    '<ul class="formatitems">' + addButtons().gif.join("") + '</ul>' +
                    '</div>' +
                    '</div>'
            });
        });
    };

    return {
        init: init
    };
}()