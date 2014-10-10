var img;
var id;
var originalWidth;
var originalHeight;
var mediumWidth = 700;
var smallWidth = 350;
var imageResolutions;
var imageSettings;

//Sends properties for choosen image to controller method
var getData = function () {
    var myData;
    $.ajax({
        async: false,
        url: 'Download',
        type: 'GET',
        datatype: 'json',
        data: ("imageResolutions=" + JSON.stringify(imageResolutions) + "&id=" + id),
        success: function (response) {
            myData = response;
        }
    });
    return myData;
}

//Get id of current picture and create list of diffrerent imageresolutions for download
$(".image").click(function() {
    id = $(this).parent("li").attr("data-image-id");
    originalWidth = parseInt($(this).parent("li").attr("data-image-width"));
    originalHeight = parseInt($(this).parent("li").attr("data-image-height"));
    imageResolutions = [
        { linkName: "Original Size", format: "Jpeg", width: originalWidth },
        { linkName: "Medium Size", format: "Jpeg", width: mediumWidth },
        { linkName: "Small Size", format: "Jpeg", width: smallWidth },
        { linkName: "Original Size", format: "Png", width: originalWidth },
        { linkName: "Medium Size", format: "Png", width: mediumWidth },
        { linkName: "Small Size", format: "Png", width: smallWidth },
        { linkName: "Original Size", format: "Gif", width: originalWidth },
        { linkName: "Medium Size", format: "Gif", width: mediumWidth },
        { linkName: "Small Size", format: "Gif", width: smallWidth }
    ];
});

//Add downloadbutton to interface and save original image src, also set returnvalue of getData to variable imageSettings
$(".image").fancybox({
    beforeShow: function () {
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

//Add buttons for each resolution
var addButtons = function() {
    var buttons = { jpg: ["<li>JPG</li>"], png: ["<li>PNG</li>"], gif: ["<li>GIF</li>"] };
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



