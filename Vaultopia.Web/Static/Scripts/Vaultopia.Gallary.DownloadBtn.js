var img;
var id;
var originalWidth;
var originalHeight;
var mediumWidth = 700;
var smallWidth = 350;
var imageResolutions;

$(".image").click(function() {
    id = $(this).parent("li").attr("data-image-id");
    originalWidth = $(this).parent("li").attr("data-image-width");
    originalHeight = $(this).parent("li").attr("data-image-height");
    imageResolutions = [
        { linkName: "JPG Original Size", format: "pngdefault", width: originalWidth },
        { linkName: "PNG Original Size", format: "jpgdefault", width: originalWidth },
        { linkName: "GIF Original Size", format: "gifdefault", width: originalWidth },
        { linkName: "JPG Medium Size", format: "pngmedium", width: mediumWidth },
        { linkName: "JPG Small Size", format: "pngmedium", width: smallWidth }
    ];
});

var mediumHeight = function() {
    var newSizeRatio = originalWidth / 700;
    return Math.floor(originalHeight / newSizeRatio);
};

var smallHeight = function() {
    var newSizeRatio = originalWidth / 350;
    return Math.floor(originalHeight / newSizeRatio);
};

var addButtons = function() {
    var buttons;
    var width;
    alert(imageResolutions[0].width);
    for (var i = 0; i < imageResolutions.length;) {
        width = imageResolutions[i].width;
        switch (width) {
            case originalWidth:
                buttons += '<div id="' + imageResolutions[i].format + '" class="button formatbtn">' + imageResolutions[i].linkName + '(' + originalWidth.toString() + "x" + originalHeight.toString() + ')</div>';
                break;
            case mediumWidth:
                buttons += '<div id="' + imageResolutions[i].format + '" class="button formatbtn">' + imageResolutions[i].linkName + '('+ imageResolutions[i].width + "x" + mediumHeight().toString() + ')</div>';
                break;
            case smallWidth:
                buttons += '<div id="' + imageResolutions[i].format + '" class="button formatbtn">' + imageResolutions[i].linkName + '(' + imageResolutions[i].width + "x" + smallHeight().toString() + ')</div>';
                break;
            default:
                break;
        }
        i += 1;
    }
    return buttons;
};

$(".image").fancybox({
    beforeShow: function() {
        this.title += '<div id="displayt" class="button downloadbtn">Download</div>';
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

$(document).on('click', '#displayt', function() {

    $.fancybox({
        content: '<div class="formatbox">' +
            '<img class="formatimg" src="' + img + '" alt="" />' +
            addButtons() +
            //'<div id="pngdefault" class="button formatbtn">PNG Original Size (' + originalWidth.toString() + 'x' + originalHeight.toString() + ')</div>' +
            //'<div id="pngmedium" class="button formatbtn">PNG Medium Size (700x'+ mediumHeight().toString() +')</div>' +
            //'<div id="jpgdefault" class="button formatbtn">JPG Original Size</div>' +
            //'<div id="gifdefault" class="button formatbtn">GIF Original Size</div>' +
            '</div>'
    });
});

$(document).on('click', '.formatbtn', function (e) {
    e.preventDefault();
    var formatId = $(this).attr("id");
    for (var i = 0; i < imageResolutions.length;) {
        if (imageResolutions[i].format == formatId){
            $.ajax({
                url: 'Download',
                type: 'GET',
                data: ("imageId=" + id + "&format=" + imageResolutions[i].format + "&width=" + imageResolutions[i].width),
                datatype: "string",
                success: function(data) {
                    var myUrl = encodeURI(data);
                    var pom = document.createElement('a');
                    pom.setAttribute('href', myUrl);
                    pom.setAttribute('download', imageResolutions[i].linkName);
                    pom.click();
                }
            });
            break;
            
        }
        i += 1;
    }
});



