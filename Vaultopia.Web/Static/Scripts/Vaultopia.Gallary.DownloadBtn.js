var img;
var id;
var imageResolutions = [
{linkName: "JPG Original Size", format: "png", width: "default" },
{linkName: "PNG Original Size", format: "jpg", width: "default" },
{linkName: "GIF Original Size", format: "gif", width: "default"}
];

$(".image").click(function() {
    id = $(this).parent("li").attr("data-image-id");
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
            '<div id="png" class="button formatbtn">PNG</div>' +
            '<div id="jpg" class="button formatbtn">JPG</div>' +
            '<div id="gif" class="button formatbtn">GIF</div>' +
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



