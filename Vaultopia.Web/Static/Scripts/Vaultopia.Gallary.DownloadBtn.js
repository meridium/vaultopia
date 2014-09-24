var img;
var id;
var originalWidth;
var imageResolutions = [
{linkName: "JPG Original Size", format: "pngdefault", width: "default" },
{linkName: "PNG Original Size", format: "jpgdefault", width: "default" },
{linkName: "GIF Original Size", format: "gifdefault", width: "default" },
{linkName: "JPG (400x", format: "pngmedium", width: "400"}
];

$(".image").click(function() {
    id = $(this).parent("li").attr("data-image-id");
    originalWidth = $(this).parent("li").attr("data-image-width");
});

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
            '<div id="pngdefault" class="button formatbtn">PNG Original Size</div>' +
            '<div id="pngmedium" class="button formatbtn">PNG (400x</div>' +
            '<div id="jpgdefault" class="button formatbtn">JPG Original Size</div>' +
            '<div id="gifdefault" class="button formatbtn">GIF Original Size</div>' +
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



