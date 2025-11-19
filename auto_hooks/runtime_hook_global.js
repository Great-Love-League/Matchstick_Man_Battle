// Global runtime auto-hook
// - Hooks Game$start_run / Game$state_machine_update to expose window.__mmb_game and window.__mmb_get_state
// - Hooks Game$check_bullet_collision to detect health deltas and emit __mmb_trigger_hit
// - Non-invasive canvas parenting for p5
(function(){
  function safeGet(name){ try { return window[name]; } catch(e){ return undefined; } }
  var startName = 'Great$45$Love$45$League$Stick_Man_Battle$server$$Game$start_run';
  var checkName = 'Great$45$Love$45$League$Stick_Man_Battle$server$$Game$check_bullet_collision';
  var updateName = 'Great$45$Love$45$League$Stick_Man_Battle$server$$Game$state_machine_update';

  function attachGetter(game){
    try{
      if(!game) return;
      if(window.__mmb_game === game && typeof window.__mmb_get_state === 'function') return;
      try{ window.__mmb_game = game; }catch(e){}
      try{
        window.__mmb_get_state = function(){
          try{
            var byIndex = {};
            var maxIndex = -1;
            if(game && game.particle_list && game.particle_list.length){
              for(var i=0;i<game.particle_list.length;i++){
                var p = game.particle_list[i];
                var ctrl = (p && p.control) ? p.control : { health: 0 };
                var idx = (p && typeof p.index === 'number') ? p.index : i;
                var hp = (ctrl && typeof ctrl.health === 'number') ? ctrl.health : (ctrl && ctrl.health !== undefined ? ctrl.health : 0);
                var obj = { index: idx, health: hp };
                try{ obj.name = typeof p.name !== 'undefined' ? p.name : null; }catch(e){ obj.name = null; }
                try{ obj.avatar = typeof p.avatar !== 'undefined' ? p.avatar : null; }catch(e){ obj.avatar = null; }
                try{ obj.ammo = typeof p.ammo !== 'undefined' ? p.ammo : null; }catch(e){ obj.ammo = null; }
                try{ obj.score = typeof p.score !== 'undefined' ? p.score : null; }catch(e){ obj.score = null; }
                byIndex[idx] = obj;
                if (idx > maxIndex) maxIndex = idx;
              }
            }
            var players = [];
            if (maxIndex >= 0) {
              for (var j=0;j<=maxIndex;j++) {
                if (byIndex.hasOwnProperty(j)) players.push(byIndex[j]);
                else players.push({ index: j, health: 0, name: null, ammo: null, score: null, avatar: null });
              }
            }
            return { players: players, frame_count: (game && game.frame_count)? game.frame_count : 0 };
          }catch(e){ return { players: [], frame_count: 0 }; }
        };
      }catch(e){}
    }catch(e){}
  }

  function hookFunction(name, wrapperFactory) {
    var orig = safeGet(name);
    if(orig && typeof orig === 'function'){
      try{ window[name] = wrapperFactory(orig); }catch(e){}
    } else {
      var t = setInterval(function(){
        var f = safeGet(name);
        if(f && typeof f === 'function'){
          clearInterval(t);
          try{ window[name] = wrapperFactory(f); }catch(e){}
        }
      }, 50);
    }
  }

  hookFunction(startName, function(orig){
    return function(game){
      try{ attachGetter(game); }catch(e){}
      return orig.apply(this, arguments);
    };
  });

  hookFunction(updateName, function(orig){
    return function(self, p5_helpers){
      try{ attachGetter(self); }catch(e){}
      return orig.apply(this, arguments);
    };
  });

  hookFunction(checkName, function(orig){
    return function(self, bullet){
      try{ attachGetter(self); }catch(e){}
      try{
        var before = {};
        try{
          if(self && self.particle_list){
            for(var i=0;i<self.particle_list.length;i++){
              var p = self.particle_list[i];
              var idx = (p && typeof p.index === 'number') ? p.index : i;
              var hp = 0;
              try{ hp = (p && p.control && typeof p.control.health === 'number') ? p.control.health : (p && p.control && p.control.health !== undefined ? p.control.health : 0); }catch(e){ hp = 0; }
              before[idx] = hp;
            }
          }
        }catch(e){}
        var res = orig.apply(this, arguments);
        try{
          if(self && self.particle_list){
            for(var i=0;i<self.particle_list.length;i++){
              var p = self.particle_list[i];
              var idx = (p && typeof p.index === 'number') ? p.index : i;
              var after = 0;
              try{ after = (p && p.control && typeof p.control.health === 'number') ? p.control.health : (p && p.control && p.control.health !== undefined ? p.control.health : 0); }catch(e){ after = 0; }
              var prev = before.hasOwnProperty(idx) ? before[idx] : 0;
              var delta = prev - after;
              if(delta > 0){
                try{ if(typeof window !== 'undefined' && window.__mmb_trigger_hit){ try{ window.__mmb_trigger_hit(idx, undefined, undefined, delta); }catch(e){} } }catch(e){}
              }
            }
          }
        }catch(e){}
        return res;
      }catch(e){ try{ return orig.apply(this, arguments); }catch(e){} }
    };
  });

  // Canvas parenting helper (same non-invasive approach)
  function ensureCanvasParenting(){
    try{
      var getContainer = function(){ return (typeof document !== 'undefined') ? document.getElementById('game-container') : null; };
      function moveCanvasToContainer(c){
        try{
          var cont = getContainer();
          if(!cont || !c) return;
          if(c && typeof c.parent === 'function'){ try{ c.parent('game-container'); return; }catch(e){} }
          var node = c && (c.elt || c.canvas) ? (c.elt || c.canvas) : c;
          if(node && node.parentNode !== cont){ try{ cont.appendChild(node); }catch(e){} }
        }catch(e){}
      }
      function patchP5(){
        try{ if(window.p5 && window.p5.prototype && !window.__mmb_p5_patched){ var orig = window.p5.prototype.createCanvas; if(typeof orig === 'function'){ window.p5.prototype.createCanvas = function(){ var res = orig.apply(this, arguments); try{ setTimeout(function(){ moveCanvasToContainer(res); }, 0); }catch(e){} return res; }; window.__mmb_p5_patched = true; return true; } } }catch(e){}
      }
      if(!patchP5()){ var ppoll = setInterval(function(){ if(patchP5()){ clearInterval(ppoll); } }, 120); }
      try{
        var observer = new MutationObserver(function(muts){
          muts.forEach(function(m){ if(m.addedNodes && m.addedNodes.length){ for(var i=0;i<m.addedNodes.length;i++){ var n = m.addedNodes[i]; if(!n) continue; if(n.nodeName === 'CANVAS') moveCanvasToContainer(n); else if(n.querySelectorAll){ try{ var list = n.querySelectorAll('canvas'); for(var j=0;j<list.length;j++) moveCanvasToContainer(list[j]); }catch(e){} } } } });
        });
        if(typeof document !== 'undefined' && (document.body || document.documentElement)){
          observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
        }
      }catch(e){}
      try{ setTimeout(function(){ try{ if(typeof document !== 'undefined'){ var existing = Array.prototype.slice.call(document.querySelectorAll('canvas')); for(var k=0;k<existing.length;k++) moveCanvasToContainer(existing[k]); } }catch(e){} }, 140); }catch(e){}
    }catch(e){}
  }

  try{ ensureCanvasParenting(); }catch(e){}

})();
