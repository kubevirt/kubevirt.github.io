// jQuery to collapse the navbar on scroll
function collapseNavbar() {
  if ($(".navbar").offset().top > 50) {
    $(".fixed-top").addClass("scroll-collapse");
  } else {
    $(".fixed-top").removeClass("scroll-collapse");
  }
}

$(window).scroll(collapseNavbar);
$(document).ready(collapseNavbar);

window.twttr = (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0],
  t = window.twttr || {};
  if (d.getElementById(id)) return t;
  js = d.createElement(s);
  js.id = id;
  js.src = "https://platform.twitter.com/widgets.js";
  fjs.parentNode.insertBefore(js, fjs);

  t._e = [];
  t.ready = function(f) {
    t._e.push(f);
  };

  return t;
}(document, "script", "twitter-wjs"));

//
// This is a "hack" to customize the Twitter feed styles.
//
// Due to the dynamic rendering of the feed and the limited capabilities
// of customization, this is the best option to make it fit with the overall
// feel of the site, rather than the default Twitter design.
//
window.setTimeout(function(){
  $(".twitter-timeline").contents().find(".SandboxRoot").css("font","normal normal 14px/1.4 sans-serif");
  $(".twitter-timeline").contents().find(".timeline-Widget").css("max-width","100%");
  $(".twitter-timeline").contents().find(".timeline-Tweet").css("padding","10px 20px");
  $(".twitter-timeline").contents().find(".TweetAuthor-name").css("font-size","20px");
  $(".twitter-timeline").contents().find(".TweetAuthor-name").css("font-weight","300");
  $(".twitter-timeline").contents().find(".TweetAuthor-name").css("color","#00797f");
  $(".twitter-timeline").contents().find(".TweetAuthor-screenName").css("font-size","16px");
  $(".twitter-timeline").contents().find(".TweetAuthor-screenName").css("font-weight","300");
  $(".twitter-timeline").contents().find(".TweetAuthor-screenName").css("color","#878787");
  $(".twitter-timeline").contents().find(".timeline-Tweet-text").css("font-size","20px");
  $(".twitter-timeline").contents().find(".Icon--share").css("display","none");
  $(".twitter-timeline").contents().find(".Icon--twitter").css("display","none");
}, 2000);
