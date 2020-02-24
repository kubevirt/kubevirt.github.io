let codes = document.querySelectorAll('.highlight > pre > code > table > tbody > tr > td:nth-of-type(2)');

let countID = 0;
codes.forEach((code) => {

  code.setAttribute("id", "code" + countID);

  let btn = document.createElement('button');
  btn.innerHTML = "Copy";
  btn.className = "btn-copy";
  btn.setAttribute("data-clipboard-action", "copy");
  btn.setAttribute("data-clipboard-target", "#code" + countID);

  let div = document.createElement('div');
  div.appendChild(btn);
  code.after(div);

  var codeblock = code.parentNode
  var container = codeblock.parentNode
  var row = container.parentNode;
  var table = row.parentNode;
  var pre = table.parentNode;

  if (pre.parentNode.classList.contains('highlight')) {
    var highlight = pre.parentNode;
    highlight.parentNode.insertBefore(btn, highlight);
  } else {
    pre.parentNode.insertBefore(btn, pre);
  }


  countID++;
});

let clipboard = new ClipboardJS('.btn-copy');
