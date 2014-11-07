//$(document).ready(function () {
//    if ($('aside').children().length === 0) {
//        //document.getElementsByClassName('NewsText').style.width = '100%';
//        $(".paddingProcessMap").css({ width: "100%" });
//        $("aside").css("display", "none");
//    } else {
//        //document.getElementsByClassName('NewsText').style.width = '60%';
//        $(".processMap").css({ width: "77%" });
//        $("aside").css("width", "23%");
//    }
//});

$(document).ready(function(){
    $("a.test").each(function( ) {
        var url =  $(this).children("img").attr("src");
        $(this).attr('href', url);
    });
    $("a.test").fancybox();
});
