const pfp = document.getElementById("pfp");
const originalTitle = document.title;

pfp.addEventListener("click", () => {

  pfp.style.animation = "bounce 0.6s";
  pfp.addEventListener("animationend", () => {
    pfp.style.animation = "";
  }, { once: true });


  document.title = "hello, hello, 1 2 3";
  setTimeout(() => {
    document.title = originalTitle;
  }, 1000);
});
