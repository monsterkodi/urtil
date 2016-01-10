
/*
000   000  00000000   000000000  000  000    
000   000  000   000     000     000  000    
000   000  0000000       000     000  000    
000   000  000   000     000     000  000    
 0000000   000   000     000     000  0000000
 */

(function() {
  var _, args, buildPage, childp, coff, coffee, colors, css, defaultScreenHeight, defaultTileHeight, defaultTileWidth, del, err, ext, fs, has, html, img, indir, j, jade, k, l, len, len1, load, log, m, map, mkpath, name, noon, numLoaded, onLoaded, onTimeout, open, outdir, path, process, ref, ref1, resolve, rm, script, sds, set, sites, status, styl, stylus, swapAlias, tile, tiles, u, url, urls, webshot,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  fs = require('fs');

  url = require('url');

  rm = require('del');

  sds = require('sds');

  open = require('opn');

  jade = require('jade');

  noon = require('noon');

  path = require('path');

  colors = require('colors');

  stylus = require('stylus');

  _ = require('lodash');

  mkpath = require('mkpath');

  webshot = require('webshot');

  process = require('process');

  childp = require('child_process');

  coffee = require('coffee-script');

  resolve = function(unresolved) {
    var p;
    p = unresolved.replace(/\~/, process.env.HOME);
    p = path.resolve(p);
    p = path.normalize(p);
    return p;
  };

  log = console.log;

  err = function() {
    log(colors.bold.red([].slice.call(arguments).join(' ')));
    return process.exit();
  };

  defaultTileWidth = 240;

  defaultTileHeight = 160;

  defaultScreenHeight = 1100;


  /*
  000   000   0000000   00000000    0000000 
  000  000   000   000  000   000  000      
  0000000    000000000  0000000    000  0000
  000  000   000   000  000   000  000   000
  000   000  000   000  000   000   0000000
   */

  args = require('karg')("urtil\n      name               . ? the name of the config file   . * . = index\n      inDir              . ? location of the config files      . = .                 \n      outDir             . ? location of result files          . = .                 \n      tileWidth    . - W . ? tile width                        . = " + defaultTileWidth + "\n      tileHeight   . - H . ? tile height                       . = " + defaultTileHeight + "\n      tileSize     . - S . ? square tiles                   \n      bgColor            . ? background color                  . = #ddd\n      fgColor            . ? text color                        . = #000\n      screenHeight       . ? screen height                     . = " + defaultScreenHeight + "\n      timeout            . ? maximal page retrieval time       . = 60\n      open         . - O . ? open generated page               . = true\n      clean              . ? delete intermediate noon files    . = true\n      quiet              . ? less verbose console output       . = false     \n      verbose            . ? verbose console output            . = false\n      refresh            . ? force refresh of all tiles        . = false    \n      norefresh          . ? disable refresh of all tiles      . = false      \n      uplink       . - U . = ||\n      \nversion  " + (require(__dirname + "/../package.json").version));


  /*
  000  000   000  000  000000000
  000  0000  000  000     000   
  000  000 0 000  000     000   
  000  000  0000  000     000   
  000  000   000  000     000
   */

  indir = resolve(args.inDir);

  outdir = resolve(args.outDir);

  name = path.basename(args.name, path.extname(args.name));

  sites = resolve(indir + "/" + args.name);

  if (!fs.existsSync(sites) || fs.statSync(sites).isDirectory()) {
    ref = sds.extensions;
    for (j = 0, len = ref.length; j < len; j++) {
      ext = ref[j];
      sites = resolve(indir + "/" + name + "." + ext);
      if (fs.existsSync(sites)) {
        break;
      }
    }
  }

  if (!fs.existsSync(sites)) {
    sites = indir + "/" + name + ".crypt";
  }

  if (!fs.existsSync(sites)) {
    err("config file with name " + name.yellow + " not found in " + indir.yellow + "!");
  }

  urls = sds.load(sites);

  has = function(ol, kv) {
    if (ol == null) {
      return false;
    }
    if (_.isArray(ol)) {
      return indexOf.call(ol, kv) >= 0;
    } else {
      return indexOf.call(Object.keys(ol), kv) >= 0;
    }
  };

  set = function(ol, kv, v) {
    if (v == null) {
      v = null;
    }
    if (ol == null) {
      return;
    }
    if (_.isArray(ol)) {
      return ol.push(kv);
    } else {
      return ol[kv] = v;
    }
  };

  del = function(ol, kv) {
    if (ol == null) {
      return;
    }
    if (_.isArray(ol)) {
      return _.pull(ol, kv);
    } else {
      return delete ol[kv];
    }
  };


  /*
   0000000   000      000   0000000    0000000
  000   000  000      000  000   000  000     
  000000000  000      000  000000000  0000000 
  000   000  000      000  000   000       000
  000   000  0000000  000  000   000  0000000
   */

  swapAlias = function(ul) {
    var a, alias, len1, len2, m, n, results, swp, u, v;
    swp = function(o, a, b) {
      if (has(o, a)) {
        set(o, b, o[a]);
        return del(o, a);
      }
    };
    alias = [['-', 'break'], ['!', 'refresh'], ['sh', 'screenHeight'], ['th', 'tileHeight'], ['tw', 'tileWidth'], ['ts', 'tileSize'], ['bg', 'bgColor'], ['fg', 'fgColor'], ['@', 'config']];
    for (u in ul) {
      v = ul[u];
      for (m = 0, len1 = alias.length; m < len1; m++) {
        a = alias[m];
        swp(v, a[0], a[1]);
      }
    }
    results = [];
    for (n = 0, len2 = alias.length; n < len2; n++) {
      a = alias[n];
      results.push(swp(ul, a[0], a[1]));
    }
    return results;
  };

  swapAlias(urls);

  if (urls.config != null) {
    ref1 = ['tileWidth', 'tileHeight', 'tileSize', 'bgColor', 'fgColor'];
    for (m = 0, len1 = ref1.length; m < len1; m++) {
      k = ref1[m];
      if (urls.config[k] != null) {
        args[k] = urls.config[k];
      }
    }
    delete urls['config'];
  }

  if (args.tileSize != null) {
    args.tileWidth = args.tileSize;
    args.tileHeight = args.tileSize;
  }

  if (_.isEmpty(urls) && !args.bgColor === "#ddd") {
    err("config file seems to be empty!", noon.stringify(urls));
  }

  img = resolve(outdir + "/img/");

  map = {};

  html = resolve(outdir + "/" + name + ".html");

  load = function(f) {
    var e, error;
    try {
      return fs.readFileSync(f, {
        encoding: 'utf8'
      });
    } catch (error) {
      e = error;
      err("can't read file", f.yellow, e.magenta);
      return process.exit(-1);
    }
  };

  tiles = load(path.join(__dirname, '../jade/tiles.jade'));

  tile = load(path.join(__dirname, '../jade/tile.jade'));

  styl = load(path.join(__dirname, '../jade/tiles.styl'));

  styl = _.template(styl)(args);

  css = stylus.render(styl);

  coff = load(path.join(__dirname, '../jade/tiles.coffee'));

  coff = _.template(coff)(args);

  script = coffee.compile(coff);

  mkpath.sync(img);


  /*
   0000000  000000000   0000000   000000000  000   000   0000000
  000          000     000   000     000     000   000  000     
  0000000      000     000000000     000     000   000  0000000 
       000     000     000   000     000     000   000       000
  0000000      000     000   000     000      0000000   0000000
   */

  status = function() {
    var c, s;
    if (args.quiet) {
      return;
    }
    process.stdout.clearLine();
    process.stdout.cursorTo(0);
    s = _.map(urls, function(v, u) {
      var ref2;
      if (((ref2 = map[u]) != null ? ref2.status : void 0) == null) {
        return '██'.gray;
      } else if (map[u].fixed) {
        return '██'.bold.yellow;
      } else if (map[u].cached) {
        return '██'.magenta;
      } else if ('ok' === map[u].status.strip) {
        if (map[u].local) {
          return '██'.bold.white;
        } else {
          return '██'.bold.green;
        }
      } else {
        return '██'.bold.blue;
      }
    });
    s = '  ' + s.join('');
    c = process.stdout.getWindowSize()[0];
    while (s.strip.length >= c) {
      s = s.substr(0, s.length - 2);
    }
    log(s);
    process.stdout.cursorTo(0);
    return process.stdout.moveCursor(0, -1);
  };


  /*
  0000000    000   000  000  000      0000000   
  000   000  000   000  000  000      000   000 
  0000000    000   000  000  000      000   000 
  000   000  000   000  000  000      000   000 
  0000000     0000000   000  0000000  0000000
   */

  buildPage = function() {
    var breakLast, h, i, n, r, t, u;
    t = tiles;
    breakLast = false;
    for (u in map) {
      i = map[u];
      t += _.template(tile)({
        href: i.href,
        img: path.join('img', i.img),
        width: args.tileWidth,
        height: args.tileHeight,
        name: _.last(u.split('/'))
      });
      if (has(urls[u], 'break')) {
        t += "        div.break\n";
        breakLast = true;
      } else {
        breakLast = false;
      }
    }
    if (!breakLast) {
      for (i = n = 0; n < 4; i = ++n) {
        t += "        span.site.empty\n";
      }
    }
    h = jade.render(t, {
      name: name,
      pretty: true
    });
    r = _.template(h)({
      style: css,
      script: script
    });
    fs.writeFileSync(html, r);
    if (args.open) {
      return open(html);
    }
  };


  /*
  000       0000000    0000000   0000000  
  000      000   000  000   000  000   000
  000      000   000  000000000  000   000
  000      000   000  000   000  000   000
  0000000   0000000   000   000  0000000
   */

  load = function(u, cb) {
    var cmd, f, fexists, local, o, p, r, refresh, sh, uc, us;
    local = u.indexOf('.') === -1;
    if (local) {
      us = "file://" + (resolve(path.join(outdir, u + '.html')));
    } else if (!u.startsWith('http')) {
      us = "http://" + u;
    } else {
      us = u;
    }
    r = url.parse(us);
    map[u] = {
      href: local && ("./" + u + ".html") || r.href
    };
    if (local) {
      map[u].local = true;
    }
    if (has(urls[u], 'image')) {
      f = urls[u].image;
      map[u].fixed = true;
    } else if (local) {
      f = u + ".png";
    } else {
      p = r.path !== '/' && r.path.replace(/\//g, '.') || '';
      p = p.replace(/[~]/g, '_');
      f = path.join(r.hostname + p + '.png');
    }
    map[u].img = "" + f;
    f = resolve(path.join(img, f));
    refresh = has(urls[u], 'refresh');
    if (args.refresh) {
      refresh = true;
    }
    if (args.norefresh || map[u].fixed) {
      refresh = false;
    }
    fexists = fs.existsSync(f);
    if (fexists && !refresh) {
      map[u].cached = true;
      map[u].status = 'ok'.green;
      return cb(u);
    } else {
      if (fexists) {
        fs.renameSync(f, path.join(img, "." + map[u].img));
      }

      /*
      000   000  000000000  00     00  000    
      000   000     000     000   000  000    
      000000000     000     000000000  000    
      000   000     000     000 0 000  000    
      000   000     000     000   000  0000000
       */
      if (has(urls[u], 'html')) {
        delete urls[u]['html'];
        uc = _.clone(urls[u]);
        swapAlias(uc);
        delete uc['break'];
        delete uc['refresh'];
        delete uc['tileSize'];
        delete uc['tileWidth'];
        delete uc['tileHeight'];
        delete uc['screenHeight'];
        sds.save(u + ".noon", uc);
        cmd = process.argv[0] + " " + process.argv[1] + " -O -U ./" + name + ".html " + u + ".noon";
        if (args.verbose) {
          cmd += " -v";
        }
        if (args.quiet) {
          cmd += " -q";
        }
        if (args.refresh) {
          cmd += " -r";
        }
        childp.execSync(cmd, {
          cwd: process.cwd(),
          encoding: 'utf8',
          stdio: 'inherit'
        });
        if (args.clean) {
          rm.sync(u + ".noon");
        }
        if (!args.quiet) {
          log('');
        }
      }
      sh = has(urls[u], 'screenHeight') && urls[u].screenHeight || args.screenHeight;
      o = {
        windowSize: {
          width: parseInt(sh * args.tileWidth / args.tileHeight),
          height: sh
        },
        shotSize: {
          width: 'window',
          height: 'window'
        },
        defaultWhiteBackground: true
      };
      return webshot(us, f, o, (function(_this) {
        return function(e) {
          if (e) {
            map[u].status = 'failed'.red;
          } else {
            map[u].status = 'ok'.green;
          }
          return cb(u);
        };
      })(this));
    }
  };


  /*
   0000000   0000000   0000000   000   000
  000       000       000   000  0000  000
  0000000   000       000000000  000 0 000
       000  000       000   000  000  0000
  0000000    0000000  000   000  000   000
   */

  if (_.isEmpty(urls)) {
    buildPage();
    process.exit(0);
  }

  numLoaded = 0;

  onLoaded = function(u) {
    var c, f, i;
    numLoaded += 1;
    i = map[u];
    f = path.join(img, i.img);
    c = path.join(img, "." + i.img);
    if (i.status == null) {
      i.status = 'timeout'.red;
    }
    if ('ok' !== i.status.strip) {
      if (fs.existsSync(c)) {
        fs.renameSync(c, f);
      }
    }
    if (numLoaded === _.size(urls)) {
      if (!args.quiet && args.verbose) {
        process.stdout.clearLine();
        process.stdout.cursorTo(0);
        process.stdout.moveCursor(0, -1);
        log(noon.stringify(map, {
          colors: true
        }));
      }
      buildPage();
      status();
      if (args.uplink === '' && !args.quiet) {
        log('');
      }
      return process.exit(0);
    } else {
      return status();
    }
  };

  if (_.isArray(urls)) {
    l = (function() {
      var len2, n, results;
      results = [];
      for (n = 0, len2 = urls.length; n < len2; n++) {
        u = urls[n];
        results.push(load(u, onLoaded));
      }
      return results;
    })();
  } else {
    l = (function() {
      var results;
      results = [];
      for (u in urls) {
        results.push(load(u, onLoaded));
      }
      return results;
    })();
  }

  onTimeout = function() {
    if (!args.quiet) {
      if (args.verbose) {
        process.stdout.clearLine();
        process.stdout.cursorTo(0);
        process.stdout.moveCursor(0, -1);
        log(noon.stringify(map, {
          colors: true
        }));
      } else {
        process.stdout.clearLine();
        process.stdout.cursorTo(0);
        process.stdout.moveCursor(0, -1);
      }
      log('       timeout       '.bold.yellow.bgRed);
      if (args.uplink !== '') {
        buildPage();
      }
      status();
      if (args.uplink === '') {
        log('');
      }
    }
    return process.exit(0);
  };

  setTimeout(onTimeout, args.timeout * 1000);

}).call(this);
