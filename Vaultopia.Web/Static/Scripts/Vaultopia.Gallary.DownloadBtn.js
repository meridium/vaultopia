var img;
var id;
var originalWidth;
var originalHeight;
var mediumWidth = 700;
var smallWidth = 350;
var imageResolutions;
var mediumHeight = function () {
    var newSizeRatio = originalWidth / 700;
    return Math.floor(originalHeight / newSizeRatio);
};

var smallHeight = function () {
    var newSizeRatio = originalWidth / 350;
    return Math.floor(originalHeight / newSizeRatio);
};

$(".image").click(function() {
    id = $(this).parent("li").attr("data-image-id");
    originalWidth = $(this).parent("li").attr("data-image-width");
    originalHeight = $(this).parent("li").attr("data-image-height");
    imageResolutions = [
        { linkName: "Original Size", format: "jpg", width: originalWidth, height: originalHeight },
        { linkName: "Medium Size", format: "jpg", width: mediumWidth, height: mediumHeight() },
        { linkName: "Small Size", format: "jpg", width: smallWidth, height: smallHeight() },
        { linkName: "Original Size", format: "png", width: originalWidth, height: originalHeight },
        { linkName: "Medium Size", format: "png", width: mediumWidth, height: mediumHeight() },
        { linkName: "Small Size", format: "png", width: smallWidth, height: smallHeight() },
        { linkName: "Original Size", format: "gif", width: originalWidth, height: originalHeight },
        { linkName: "Medium Size", format: "gif", width: mediumWidth, height: mediumHeight() },
        { linkName: "Small Size", format: "gif", width: smallWidth, height: smallHeight() }
    ];
});

$(".image").fancybox({
    beforeShow: function () {
        this.title += '<div id="displayformats" class="button downloadbtn">Download</div>';
    },
    afterShow: function () {
        img = this.href;
    },
    helpers: {
        title: {
            type: 'inside'
        }
    }
});

var addButtons = function() {
    var buttons = { jpg: ["<li>JPG</li>"], png: ["<li>PNG</li>"], gif: ["<li>GIF</li>"] };
    var format;
    for (var i = 0; i < imageResolutions.length;) {
        if (originalWidth > imageResolutions[i].width || originalWidth === imageResolutions[i].width) { 
            format = imageResolutions[i].format;
            var listItem = '<li data-format-width="' + imageResolutions[i].width + '" data-format-type="' + imageResolutions[i].format + '">' + imageResolutions[i].linkName + ' (' + imageResolutions[i].width.toString() + 'x'+ imageResolutions[i].height.toString() + ')</li>';
            switch (format) {
                case "jpg":
                    buttons.jpg.push(listItem);
                    break;
                case "png":
                    buttons.png.push(listItem);
                    break;
                case "gif":
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

$(document).on('click', '#displayformats', function () {
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

$(document).on('click', '.formatitems li', function (e) {
    e.preventDefault();
    var formatType = $(this).attr("data-format-type");
    var formatWidth = $(this).attr("data-format-width");
        $.ajax({
            url: 'Download',
            type: 'GET',
            data: ("imageId=" + id + "&format=" + formatType + "&width=" + formatWidth),
            datatype: "string",
            success: function(data) {
                var myUrl = encodeURI(data);
                var a = document.createElement('a');
                if (typeof a.download != "undefined") {
                    a.setAttribute('href', myUrl);
                    a.setAttribute('download', id);
                    a.click();
                }
                else {;
                    window.open(myUrl, '_blank');
                }
            }
        });
});



