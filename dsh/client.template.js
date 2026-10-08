window.__ModuleLoader__.load({
  id: '@local/dsh-naiyou-pet',
  factory(require) {
    const React = require('react');
    const h = React.createElement;
    const SPRITESHEET = '__SPRITESHEET_DATA_URL__';
    const KEY = 'dsh.naiyou-pet.preferences.v1';
    const NS = 'naiyou-pet';
    const ANIMATIONS = [
      { key: 'idle', row: 0, count: 6, fps: 6 },
      { key: 'right', row: 1, count: 8, fps: 9 },
      { key: 'left', row: 2, count: 8, fps: 9 },
      { key: 'wave', row: 3, count: 4, fps: 5 },
      { key: 'jump', row: 4, count: 5, fps: 7 },
      { key: 'think', row: 5, count: 8, fps: 5 },
      { key: 'type', row: 6, count: 6, fps: 7 },
      { key: 'wait', row: 7, count: 6, fps: 5 },
      { key: 'happy', row: 8, count: 6, fps: 7 },
    ];
    const DICTIONARIES = {
      zh: {
        name: '奶邮', idle: '陪你一起工作', busy: '思考中…', waiting: '等你回应',
        happy: '完成啦！', pet: '点点奶邮，让它和你打个招呼',
        settings: '奶邮设置', close: '关闭设置', show: '显示奶邮', hide: '隐藏奶邮',
        size: '大小', small: '小', medium: '中', large: '大', drag: '拖动奶邮', reset: '重置位置',
        animation: '动画', auto: '自动', pause: '暂停动画',
        idleMotion: '待机', rightMotion: '向右走', leftMotion: '向左走',
        waveMotion: '打招呼', jumpMotion: '蹦跳', thinkMotion: '思考',
        typeMotion: '忙碌', waitMotion: '等待', happyMotion: '开心',
      },
      en: {
        name: 'Naiyou', idle: 'Here with you', busy: 'Thinking…', waiting: 'Waiting for you',
        happy: 'All done!', pet: 'Tap Naiyou to say hello',
        settings: 'Naiyou settings', close: 'Close settings', show: 'Show Naiyou', hide: 'Hide Naiyou',
        size: 'Size', small: 'Small', medium: 'Medium', large: 'Large', drag: 'Drag Naiyou', reset: 'Reset position',
        animation: 'Animation', auto: 'Automatic', pause: 'Pause animation',
        idleMotion: 'Idle', rightMotion: 'Walk right', leftMotion: 'Walk left',
        waveMotion: 'Wave', jumpMotion: 'Jump', thinkMotion: 'Think',
        typeMotion: 'Busy', waitMotion: 'Wait', happyMotion: 'Happy',
      },
    };
    const CSS = `
      .dsh-naiyou{display:flex;align-items:center;gap:6px;max-width:calc(100vw - 24px);color:var(--dsw-alias-label-secondary,currentColor);font:inherit;position:fixed;right:20px;top:calc(var(--dsh-frame-top-clearance,0px) + 16px);z-index:8;pointer-events:auto;flex:none}
      .dsh-naiyou button,.dsh-naiyou select{font:inherit;color:inherit;cursor:pointer}
      .dsh-naiyou button{border:0;background:transparent;padding:4px;border-radius:8px}
      .dsh-naiyou button:hover{background:var(--dsw-alias-interactive-bg-hover-solid,rgba(127,127,127,.1))}
      .dsh-naiyou button:focus-visible,.dsh-naiyou select:focus-visible{outline:2px solid #4d8aff;outline-offset:2px}
      .dsh-naiyou .dsh-naiyou-sprite{padding:0;background-color:transparent;flex:none;overflow:hidden;background-repeat:no-repeat;border-radius:0}
      .dsh-naiyou .dsh-naiyou-sprite:hover{background-color:transparent}
      .dsh-naiyou-copy{display:flex;flex-direction:column;gap:4px;min-width:0;font-size:12px;line-height:1.4}
      .dsh-naiyou-name{font-weight:500;color:var(--dsw-alias-label-primary,currentColor)}
      .dsh-naiyou-status{font-size:11px;white-space:nowrap;color:var(--dsw-alias-label-tertiary,currentColor)}
      .dsh-naiyou-gear{font-size:16px;line-height:1;margin-left:2px}
      .dsh-naiyou-options{position:absolute;right:0;top:100%;z-index:10;box-sizing:border-box;width:210px;padding:12px;border:1px solid var(--dsw-alias-border-l2,rgba(127,127,127,.3));border-radius:12px;background:var(--dsw-specific-menu,Canvas);color:var(--dsw-alias-label-primary,CanvasText);box-shadow:0 4px 20px #0002;font-size:12px}
      .dsh-naiyou-options header{display:flex;align-items:center;justify-content:space-between;margin-bottom:8px}
      .dsh-naiyou-options label{display:flex;align-items:center;justify-content:space-between;gap:10px;margin:8px 0}
      .dsh-naiyou-options select{background:var(--dsw-alias-interactive-bg-hover-solid,Canvas);border:1px solid var(--dsw-alias-border-l2,#8886);border-radius:6px;padding:4px;max-width:122px}
      .dsh-naiyou-options input{accent-color:#4d8aff}
      .dsh-naiyou-show{font-size:11px!important;white-space:nowrap}
      .dsh-naiyou .dsh-naiyou-drag{cursor:grab;touch-action:none;font-size:14px;padding:3px;color:var(--dsw-alias-label-tertiary,currentColor)}
      .dsh-naiyou .dsh-naiyou-drag:active{cursor:grabbing}
      @media(max-width:600px){.dsh-naiyou-copy{display:none}.dsh-naiyou{gap:0}}
    `;
    function readPreferences() {
      try {
        const value = JSON.parse(localStorage.getItem(KEY) || '{}');
        return {
          hidden: value.hidden === true,
          size: [64, 80, 104].includes(value.size) ? value.size : 80,
          animation: value.animation === 'auto' || ANIMATIONS.some(a => a.key === value.animation) ? value.animation : 'auto',
          paused: value.paused === true,
          position: value.position && Number.isFinite(value.position.x) && Number.isFinite(value.position.y) ? value.position : null,
        };
      } catch { return { hidden: false, size: 80, animation: 'auto', paused: false, position: null }; }
    }
    function Pet({ t, useSessions, useSessionStatus }) {
      const [prefs, setPrefs] = React.useState(readPreferences);
      const [settings, setSettings] = React.useState(false);
      const [gesture, setGesture] = React.useState(null);
      const [look, setLook] = React.useState(null);
      const [frame, setFrame] = React.useState(0);
      const [visible, setVisible] = React.useState(() => !document.hidden);
      const [reduced, setReduced] = React.useState(() => window.matchMedia('(prefers-reduced-motion: reduce)').matches);
      const lastRunning = React.useRef(false);
      const rootRef = React.useRef(null);
      const dragRef = React.useRef(null);
      const sessionId = useSessions?.(sessions => Object.values(sessions.byId || {}).find(session => (session.retainedBy?.mainView || 0) > 0)?.id);
      const status = useSessionStatus?.(statuses => statuses.get(sessionId));
      const running = status?.running === true;
      const waiting = Boolean(status?.pendingInteraction);
      const selected = prefs.animation === 'auto'
        ? (gesture || (waiting ? 'wait' : running ? 'think' : 'idle'))
        : prefs.animation;
      const animation = ANIMATIONS.find(a => a.key === selected) || ANIMATIONS[0];
      React.useEffect(() => {
        try { localStorage.setItem(KEY, JSON.stringify(prefs)); } catch {}
      }, [prefs]);
      React.useEffect(() => {
        const onVisibility = () => setVisible(!document.hidden);
        const media = window.matchMedia('(prefers-reduced-motion: reduce)');
        const onMotion = () => setReduced(media.matches);
        const onResize = () => setPrefs(current => {
          if (!current.position || !rootRef.current) return current;
          const bounds = rootRef.current.getBoundingClientRect();
          const x = Math.max(8, Math.min(current.position.x, window.innerWidth - bounds.width - 8));
          const y = Math.max(48, Math.min(current.position.y, window.innerHeight - bounds.height - 8));
          return x === current.position.x && y === current.position.y ? current : { ...current, position: { x, y } };
        });
        document.addEventListener('visibilitychange', onVisibility);
        media.addEventListener('change', onMotion);
        window.addEventListener('resize', onResize);
        onResize();
        return () => {
          document.removeEventListener('visibilitychange', onVisibility);
          media.removeEventListener('change', onMotion);
          window.removeEventListener('resize', onResize);
        };
      }, [prefs.size, prefs.hidden]);
      React.useEffect(() => {
        if (lastRunning.current && !running && !waiting) setGesture('happy');
        lastRunning.current = running;
      }, [running, waiting]);
      React.useEffect(() => {
        if (!gesture) return;
        const timer = setTimeout(() => setGesture(null), gesture === 'happy' ? 2800 : 1600);
        return () => clearTimeout(timer);
      }, [gesture]);
      React.useEffect(() => {
        setFrame(0);
        if (prefs.hidden || prefs.paused || reduced || !visible || look !== null) return;
        let current = 0;
        const timer = setInterval(() => {
          current = (current + 1) % animation.count;
          setFrame(current);
        }, 1000 / animation.fps);
        return () => clearInterval(timer);
      }, [animation.key, prefs.hidden, prefs.paused, reduced, visible, look]);
      const update = patch => setPrefs(current => ({ ...current, ...patch }));
      const row = look === null ? animation.row : 9 + Math.floor(look / 8);
      const column = look === null ? frame % animation.count : look % 8;
      const width = prefs.size;
      const height = width * 208 / 192;
      const statusKey = waiting ? 'waiting' : running ? 'busy' : gesture === 'happy' ? 'happy' : 'idle';
      const onLook = event => {
        if (prefs.paused || reduced) return;
        const bounds = event.currentTarget.getBoundingClientRect();
        const angle = Math.atan2(event.clientX - bounds.left - bounds.width / 2, -(event.clientY - bounds.top - bounds.height / 2));
        setLook((Math.round(angle / (Math.PI / 8)) + 16) % 16);
      };
      const onDragStart = event => {
        if (event.button !== 0) return;
        const bounds = rootRef.current.getBoundingClientRect();
        dragRef.current = { dx: event.clientX - bounds.left, dy: event.clientY - bounds.top };
        event.currentTarget.setPointerCapture(event.pointerId);
        setSettings(false);
      };
      const onDragMove = event => {
        if (!dragRef.current) return;
        const bounds = rootRef.current.getBoundingClientRect();
        update({ position: {
          x: Math.max(8, Math.min(event.clientX - dragRef.current.dx, window.innerWidth - bounds.width - 8)),
          y: Math.max(48, Math.min(event.clientY - dragRef.current.dy, window.innerHeight - bounds.height - 8)),
        } });
      };
      const onDragEnd = () => { dragRef.current = null; };
      return h('div', { ref: rootRef, className: 'dsh-naiyou', 'data-naiyou-pet': true,
        style: prefs.position ? { left: prefs.position.x, top: prefs.position.y, right: 'auto' } : undefined,
      },
        h('style', null, CSS),
        prefs.hidden ? h('button', { className: 'dsh-naiyou-show', onClick: () => update({ hidden: false }) }, t('show')) :
          h(React.Fragment, null,
            h('button', {
              type: 'button', className: 'dsh-naiyou-sprite', 'aria-label': t('pet'), title: t('pet'),
              'data-naiyou-state': look === null ? animation.key : 'look',
              'data-naiyou-frame': `${row}:${column}`,
              style: { width, height, backgroundImage: `url("${SPRITESHEET}")`, backgroundSize: `${width * 8}px ${height * 11}px`, backgroundPosition: `${-column * width}px ${-row * height}px` },
              onClick: () => { setLook(null); setGesture(current => current === 'wave' ? 'jump' : 'wave'); },
              onPointerMove: onLook, onPointerLeave: () => setLook(null),
            }),
            h('div', { className: 'dsh-naiyou-copy' },
              h('span', { className: 'dsh-naiyou-name' }, t('name')),
              h('span', { className: 'dsh-naiyou-status', 'aria-live': 'polite' }, t(statusKey))),
            h('button', { type: 'button', className: 'dsh-naiyou-drag', 'aria-label': t('drag'), title: t('drag'),
              onPointerDown: onDragStart, onPointerMove: onDragMove, onPointerUp: onDragEnd, onPointerCancel: onDragEnd,
              onKeyDown: event => {
                const deltas = { ArrowLeft: [-16, 0], ArrowRight: [16, 0], ArrowUp: [0, -16], ArrowDown: [0, 16] };
                if (!deltas[event.key]) return;
                event.preventDefault();
                const bounds = rootRef.current.getBoundingClientRect();
                const [dx, dy] = deltas[event.key];
                update({ position: { x: Math.max(8, Math.min(bounds.left + dx, window.innerWidth - bounds.width - 8)), y: Math.max(48, Math.min(bounds.top + dy, window.innerHeight - bounds.height - 8)) } });
              },
            }, '⠿'),
            h('button', { type: 'button', className: 'dsh-naiyou-gear', 'aria-label': t('settings'), title: t('settings'), 'aria-expanded': settings, onClick: () => setSettings(value => !value) }, '⚙'),
            settings && h('section', { className: 'dsh-naiyou-options', 'aria-label': t('settings'),
              style: prefs.position && prefs.position.y + height + 260 > window.innerHeight ? { top: 'auto', bottom: 'calc(100% + 8px)' } : undefined,
              onKeyDown: event => { if (event.key === 'Escape') { setSettings(false); event.stopPropagation(); } } },
              h('header', null, h('strong', null, t('settings')), h('button', { type: 'button', 'aria-label': t('close'), onClick: () => setSettings(false) }, '×')),
              h('label', null, t('size'), h('select', { value: prefs.size, onChange: event => update({ size: Number(event.target.value) }) },
                ...[[64, 'small'], [80, 'medium'], [104, 'large']].map(([size, key]) => h('option', { key, value: size }, t(key))))),
              h('label', null, t('animation'), h('select', { value: prefs.animation, onChange: event => { setLook(null); update({ animation: event.target.value }); } },
                h('option', { value: 'auto' }, t('auto')),
                ...ANIMATIONS.map(a => h('option', { key: a.key, value: a.key }, t(`${a.key}Motion`))))),
              h('label', null, t('pause'), h('input', { type: 'checkbox', checked: prefs.paused, onChange: event => update({ paused: event.target.checked }) })),
              h('button', { type: 'button', onClick: () => update({ position: null }) }, t('reset')),
              h('button', { type: 'button', onClick: () => { update({ hidden: true }); setSettings(false); setLook(null); } }, t('hide')))));
    }
    return {
      inject: ['slots', 'locale'],
      apply(ctx) {
        // Desktop uses a native always-on-top companion; browsers retain the overlay.
        if (window.location.protocol === 'dsh-app:') return;
        ctx.effect(() => ctx.locale.register(NS, DICTIONARIES), 'naiyou: translations');
        ctx.slots.inject('shell.overlay', () => ctx.slots.register({
          name: 'shell.overlay', id: 'naiyou-pet', order: 5, locale: NS,
        }, Pet));
      },
    };
  },
});
