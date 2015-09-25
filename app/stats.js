'use strict';

// stats.js - http://github.com/mrdoob/stats.js

/**
 * @author mrdoob / http://mrdoob.com/
 */

var usage = require('usage');

var Stats = function () {
  var now = (self.performance && self.performance.now) ? self.performance.now.bind(performance) : Date.now;

  var startTime = now();
  var prevTime = startTime;
  var frames = 0;
  var mode = 0;
  var pid = process.pid;
  var gridWidth = 94;
  var gridHeight = 20;
  var textHeight = 15;
  var panelWidth = gridWidth + 6;
  var panelHeight = gridHeight + textHeight;

  function createElement(tag, id, css) {
    var element = document.createElement(tag);
    element.id = id;
    element.style.cssText = css;
    return element;
  }

  function createPanel(id, fg, bg) {
    var div = createElement('div', id, 'display: inline-block; padding: 0 0 3px 3px; text-align: left; background: ' + bg + '; width: ' + (panelWidth) + 'px; height: ' + (panelHeight) + 'px;');

    var text = createElement('div', id + 'Text', 'font-family: Helvetica,Arial,sans-serif; font-size: 9px; font-weight: bold; line-height: ' + (textHeight) + 'px; color: ' + fg);
    text.innerHTML = id.toUpperCase();
    div.appendChild(text);

    var graph = createElement('div', id + 'Graph', 'width: ' + (gridWidth) + 'px; height: ' + (gridHeight) + 'px; background: ' + fg);
    div.appendChild(graph);

    for (var i = 0; i < 94; i ++) {
      graph.appendChild(createElement('span', '', 'width: 1px; height: ' + (gridHeight) + 'px; float: left; opacity: 0.9; background: ' + bg));
    }

    return div;
  }

  // function setMode(value) {
  //   var children = container.children;
  //   for (var i = 0; i < children.length; i ++) {
  //     children[i].style.display = i === value ? 'block' : 'none';
  //   }
  //   mode = value;
  // }

  function updateGraph(dom, value) {
    var child = dom.appendChild(dom.firstChild);
    child.style.height = Math.min(gridHeight, gridHeight - value * gridHeight) + 'px';
  }

  var container = createElement('div', 'stats', 'opacity: 0.25; cursor:pointer');
  // container.addEventListener('mousedown', function (event) {
  //   event.preventDefault();
  //   setMode(++ mode % container.children.length);
  // }, false);

  container.addEventListener('mouseover', function (event) {
    event.preventDefault();
    container.style.opacity = '0.75';
  }, false);

  container.addEventListener('mouseout', function (event) {
    event.preventDefault();
    container.style.opacity = '0.3';
  }, false);

  // FPS
  var fps = 0, fpsMin = Infinity, fpsMax = 0;
  var fpsDiv = createPanel('fps', '#0ff', '#002');
  var fpsText = fpsDiv.children[0];
  var fpsGraph = fpsDiv.children[1];
  container.appendChild(fpsDiv);

  // MS
  var ms = 0, msMin = Infinity, msMax = 0;
  var msDiv = createPanel('ms', '#0f0', '#020');
  var msText = msDiv.children[0];
  var msGraph = msDiv.children[1];
  container.appendChild(msDiv);
  var msbuf = [];

  // MEM
  if (self.performance && self.performance.memory) {
    var mem = 0, memMin = Infinity, memMax = 0;
    var memDiv = createPanel('mb', '#f08', '#201');
    var memText = memDiv.children[0];
    var memGraph = memDiv.children[1];
    container.appendChild(memDiv);
  }

  // CPU
  var cpu = 0, cpuMin = Infinity, cpuMax = 0;
  var cpuDiv = createPanel('%', '#f99', '#411');
  var cpuText = cpuDiv.children[0];
  var cpuGraph = cpuDiv.children[1];
  container.appendChild(cpuDiv);

  // setMode(mode);

  return {
    REVISION: 14,
    domElement: container,
    // setMode: setMode,

    begin: function () {
      startTime = now();
    },

    end: function () {
      var time = now();

      ms = time - startTime;
      msMin = Math.min(msMin, ms);
      msMax = Math.max(msMax, ms);
      msText.textContent = (ms | 0) + ' MS (' + (msMin | 0) + '-' + (msMax | 0) + ')';
      msbuf.push(ms / 200);

      frames ++;

      if (time > prevTime + 1000) {
        for (var i = 0; i < msbuf.length; i++) {
          updateGraph(msGraph, msbuf[i]);
        }
        msbuf.length = 0

        fps = Math.round((frames * 1000) / (time - prevTime));
        fpsMin = Math.min(fpsMin, fps);
        fpsMax = Math.max(fpsMax, fps);
        fpsText.textContent = fps + ' FPS (' + fpsMin + '-' + fpsMax + ')';
        updateGraph(fpsGraph, fps / 100);

        prevTime = time;
        frames = 0;

        if (mem !== undefined) {
          var heapSize = performance.memory.usedJSHeapSize;
          var heapSizeLimit = performance.memory.jsHeapSizeLimit;

          mem = Math.round(heapSize * 0.000000954);
          memMin = Math.min(memMin, mem);
          memMax = Math.max(memMax, mem);
          memText.textContent = mem + ' MB (' + memMin + '-' + memMax + ')';
          updateGraph(memGraph, heapSize / heapSizeLimit);
        }

        usage.lookup(pid, { keepHistory: true }, function (err, result) {
          cpu = result.cpu;
          cpuMin = Math.min(cpuMin, cpu);
          cpuMax = Math.max(cpuMax, cpu);
          cpuText.textContent = cpu + '% (' + cpuMin + '-' + cpuMax + ')';
          updateGraph(cpuGraph, heapSize / heapSizeLimit);
        });
      }

      return time;
    },

    update: function () {
      startTime = this.end();
    }

  };

};

if (typeof module === 'object') {
  module.exports = Stats;
}
