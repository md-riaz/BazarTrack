import { useState } from "react";

// ── Design Tokens ──────────────────────────────────────────────────────────────
const T = {
  pri:"#1565C0",priDk:"#0D47A1",priLt:"#EFF6FF",priTx:"#1E3A5F",priBd:"#BFDBFE",
  bg:"#FFFFFF",bg2:"#F8FAFC",bg3:"#F1F5F9",bd:"#E2E8F0",bd2:"#CBD5E1",
  t1:"#0F172A",t2:"#334155",t3:"#64748B",t4:"#94A3B8",
  grn:"#15803D",grnLt:"#DCFCE7",grnTx:"#14532D",grnSolid:"#166534",
  red:"#DC2626",redLt:"#FEE2E2",redTx:"#7F1D1D",redSolid:"#991B1B",
  amb:"#D97706",ambLt:"#FEF3C7",ambTx:"#78350F",neu:"#1E3A5F",
};

// ── Sample Data ────────────────────────────────────────────────────────────────
const WALLETS=[
  {id:"w1",short:"OF",name:"Office Wallet",  balance:800,   confirmed:800,  inprogress:0,   pos:true },
  {id:"w2",short:"CP",name:"CEO Personal",   balance:-1200, confirmed:-350, inprogress:-850,pos:false},
  {id:"w3",short:"CT",name:"CTO Personal",   balance:0,     confirmed:0,    inprogress:0,   pos:null },
];
const BAZARS=[
  {id:"b1",walletName:"CEO Personal", wshort:"CP",status:"open",  assigned:"Rahim",itemCount:4,spent:180, date:"আজকে"},
  {id:"b2",walletName:"Office Wallet",wshort:"OF",status:"draft", assigned:null,   itemCount:6,spent:0,   date:"আজকে"},
  {id:"b3",walletName:"CTO Personal", wshort:"CT",status:"closed",assigned:"Karim",itemCount:5,spent:2450,date:"গতকাল"},
];
const INIT_ITEMS=[
  {id:"i1",name:"পাউরুটি",  qty:"৩টা",       attrs:"",       price:180, status:"done"},
  {id:"i2",name:"গরুর মাংস",qty:"২ কেজি",   attrs:"",       price:null,status:"not_found"},
  {id:"i3",name:"দুধ",      qty:"২ প্যাকেট",attrs:"Aarong", price:null,status:"pending"},
  {id:"i4",name:"ডিম",      qty:"৩০টা",      attrs:"",       price:null,status:"pending"},
];
const FREQ=["দুধ ২ প্যাকেট","ডিম ৩০টা","পাউরুটি ৩টা","মুরগি ১ কেজি","চাল ৫ কেজি","ডাল ১ কেজি","সয়াবিন তেল","পেঁয়াজ ১ কেজি"];
const TIMELINE=[
  {msg:"Rahim পাউরুটি কিনেছে",           detail:"৩টা · ৳ ১৮০",             time:"১১:৪৫",dot:T.grn},
  {msg:"গরুর মাংস পাওয়া যায়নি",          detail:"বাজারে ছিল না",            time:"১১:২০",dot:T.red},
  {msg:"CEO দুধের qty পরিবর্তন করেছেন",  detail:"৩ প্যাকেট → ২ প্যাকেট",  time:"১০:৩২",dot:T.bd2},
  {msg:"Rahim বাজার শুরু করেছে",          detail:"৪টি item যোগ করেছে",      time:"১০:১৫",dot:T.bd2},
];
const ITEM_CFG={
  done:     {bg:T.grnLt,color:T.grnTx,icon:"✓",chipBg:T.grnLt,chipTx:T.grnTx,label:"কেনা হয়েছে"},
  not_found:{bg:T.redLt,color:T.redTx,icon:"✕",chipBg:T.redLt,chipTx:T.redTx,label:"পাওয়া যায়নি"},
  pending:  {bg:T.bg3,  color:T.t4,   icon:"○",chipBg:T.ambLt,chipTx:T.ambTx,label:"বাকি"},
  cancelled:{bg:T.bg3,  color:T.bd2,  icon:"—",chipBg:T.bg3,  chipTx:T.t3,   label:"লাগবে না"},
};

// ── Shared Components ──────────────────────────────────────────────────────────
const Chip=({bg,color,children,style})=>(
  <span style={{display:"inline-flex",alignItems:"center",gap:3,padding:"3px 9px",
    borderRadius:20,fontSize:11,fontWeight:700,background:bg,color,...style}}>{children}</span>
);
const Divider=({h=8})=><div style={{height:h,background:T.bg2,flexShrink:0}}/>;
const SectionHdr=({title,action,onAction})=>(
  <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"14px 16px 6px"}}>
    <span style={{fontSize:13,fontWeight:700,color:T.t1}}>{title}</span>
    {action&&<span style={{fontSize:12,color:T.pri,cursor:"pointer"}} onClick={onAction}>{action}</span>}
  </div>
);
const AppBar=({title,subtitle,onBack,right})=>(
  <div style={{background:T.pri,padding:"12px 16px",display:"flex",alignItems:"center",gap:10,flexShrink:0}}>
    {onBack&&<span onClick={onBack} style={{color:"#fff",fontSize:22,cursor:"pointer",marginRight:2,lineHeight:1}}>←</span>}
    <div style={{flex:1}}>
      {subtitle&&<div style={{color:"rgba(255,255,255,.75)",fontSize:10,fontWeight:700,letterSpacing:"0.05em"}}>{subtitle}</div>}
      <div style={{color:"#fff",fontSize:subtitle?16:19,fontWeight:700,letterSpacing:"-0.3px"}}>{title}</div>
    </div>
    {right}
  </div>
);
const Avatar=({label,bg,color,size=32})=>(
  <div style={{width:size,height:size,borderRadius:"50%",background:bg,color,
    display:"flex",alignItems:"center",justifyContent:"center",
    fontSize:size*0.35,fontWeight:700,flexShrink:0}}>{label}</div>
);
const SyncBadge=({status})=>{
  const c={online:{color:T.grn,label:"Synced",icon:"✓"},syncing:{color:T.pri,label:"Syncing…",icon:"⟳"},offline:{color:T.amb,label:"Offline",icon:"⚡"}}[status];
  return <span style={{fontSize:10,fontWeight:700,color:c.color,background:T.bg2,padding:"2px 7px",borderRadius:20,border:`1px solid ${T.bd}`}}>{c.icon} {c.label}</span>;
};
const Field=({label,placeholder,value,onChange,type="text",rows,style})=>(
  <div style={{margin:"0 16px 10px"}}>
    {label&&<div style={{fontSize:11,fontWeight:700,color:T.t3,marginBottom:4,letterSpacing:"0.04em"}}>{label}</div>}
    {rows
      ?<textarea rows={rows} placeholder={placeholder} value={value} onChange={e=>onChange(e.target.value)}
          style={{width:"100%",border:`1.5px solid ${T.bd}`,borderRadius:12,padding:"11px 13px",fontSize:14,color:T.t1,background:T.bg,fontFamily:"inherit",resize:"none",lineHeight:1.6,outline:"none",...style}}/>
      :<input type={type} placeholder={placeholder} value={value} onChange={e=>onChange(e.target.value)}
          style={{width:"100%",border:`1.5px solid ${T.bd}`,borderRadius:12,padding:"11px 13px",fontSize:14,color:T.t1,background:T.bg,fontFamily:"inherit",outline:"none",...style}}/>
    }
  </div>
);
const PBtn=({children,onClick,color=T.pri,style})=>(
  <button onClick={onClick} style={{background:color,color:"#fff",border:"none",borderRadius:14,
    padding:"13px 16px",fontSize:14,fontWeight:700,width:"calc(100% - 32px)",margin:"0 16px 8px",
    cursor:"pointer",fontFamily:"inherit",...style}}>{children}</button>
);
const GBtn=({children,onClick,color=T.t3,border=T.bd,style})=>(
  <button onClick={onClick} style={{background:T.bg,color,border:`1.5px solid ${border}`,borderRadius:14,
    padding:"12px 16px",fontSize:14,fontWeight:600,width:"calc(100% - 32px)",margin:"0 16px 8px",
    cursor:"pointer",fontFamily:"inherit",...style}}>{children}</button>
);
const SelectBox=({icon,label,color=T.t1,bg=T.bg,bdColor=T.bd,onClick})=>(
  <div onClick={onClick} style={{margin:"0 16px 10px",background:bg,border:`1.5px solid ${bdColor}`,borderRadius:12,
    padding:"11px 14px",display:"flex",alignItems:"center",gap:8,cursor:"pointer"}}>
    {icon&&<span style={{fontSize:18}}>{icon}</span>}
    <span style={{fontSize:14,fontWeight:700,color,flex:1}}>{label}</span>
    <span style={{fontSize:16,color:T.t3}}>▾</span>
  </div>
);
const FreqRow=({onAdd})=>(
  <div style={{display:"flex",gap:8,padding:"0 16px 10px",overflowX:"auto"}}>
    {FREQ.map(f=>(
      <span key={f} onClick={()=>onAdd(f)} style={{flexShrink:0,display:"inline-flex",alignItems:"center",gap:4,
        padding:"6px 11px",borderRadius:20,background:T.grnLt,color:T.grnTx,
        fontSize:12,fontWeight:700,cursor:"pointer",whiteSpace:"nowrap"}}>+ {f}</span>
    ))}
  </div>
);

// ── SCREEN 1: Login ────────────────────────────────────────────────────────────
const LoginScreen=({go})=>{
  const [ph,setPh]=useState("");const [pw,setPw]=useState("");
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg}}>
      <div style={{background:T.pri,padding:"44px 24px 32px",textAlign:"center"}}>
        <div style={{fontSize:40,marginBottom:10}}>🛒</div>
        <div style={{color:"#fff",fontSize:22,fontWeight:800,letterSpacing:"-0.5px"}}>সহজ বাজার খাতা</div>
        <div style={{color:"rgba(255,255,255,.7)",fontSize:13,marginTop:4}}>অফিসের বাজার হিসাব, সহজে।</div>
      </div>
      <div style={{flex:1,padding:"28px 0 0"}}>
        <Field label="ফোন নম্বর" placeholder="01XXXXXXXXX" value={ph} onChange={setPh} type="tel"/>
        <Field label="পাসওয়ার্ড" placeholder="••••••••" value={pw} onChange={setPw} type="password"/>
        <div style={{margin:"-4px 16px 16px",textAlign:"right"}}>
          <span style={{fontSize:12,color:T.pri,cursor:"pointer"}}>পাসওয়ার্ড ভুলে গেছেন?</span>
        </div>
        <PBtn onClick={()=>go("home")}>লগইন করুন →</PBtn>
        <div style={{textAlign:"center",marginTop:6,fontSize:11,color:T.t4}}>Demo: যেকোনো কিছু লিখে লগইন করুন</div>
      </div>
    </div>
  );
};

// ── SCREEN 2: Home ─────────────────────────────────────────────────────────────
const HomeScreen=({go,sync})=>(
  <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
    <div style={{background:T.pri,padding:"12px 16px 16px"}}>
      <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:12}}>
        <div>
          <div style={{color:"rgba(255,255,255,.75)",fontSize:11,fontWeight:700,letterSpacing:"0.06em"}}>সহজ বাজার খাতা</div>
          <div style={{color:"#fff",fontSize:18,fontWeight:800}}>সুপ্রভাত, Rahim 👋</div>
        </div>
        <div style={{display:"flex",flexDirection:"column",alignItems:"flex-end",gap:6}}>
          <Avatar label="R" bg="rgba(255,255,255,.2)" color="#fff" size={36}/>
          <SyncBadge status={sync}/>
        </div>
      </div>
    </div>
    <SectionHdr title="ওয়ালেট ব্যালেন্স" action="সব দেখুন →" onAction={()=>go("balance")}/>
    <div style={{display:"flex",gap:10,padding:"0 16px 4px",overflowX:"auto"}}>
      {WALLETS.map(w=>{
        const bg=w.pos===null?T.neu:w.pos?T.grnSolid:T.redSolid;
        const lbl=w.pos===null?"হিসাব মিলে গেছে ✓":w.pos?"হাতে আছে":"পাওনা আছে";
        return(<div key={w.id} onClick={()=>go("walletDetail")} style={{flexShrink:0,background:bg,borderRadius:18,padding:"14px 16px",minWidth:155,cursor:"pointer"}}>
          <div style={{color:"rgba(255,255,255,.75)",fontSize:10,fontWeight:700,letterSpacing:"0.06em",marginBottom:6}}>{w.name.toUpperCase()}</div>
          <div style={{color:"#fff",fontSize:22,fontWeight:800,letterSpacing:"-0.5px"}}>৳ {Math.abs(w.balance).toLocaleString()}</div>
          <div style={{color:"rgba(255,255,255,.75)",fontSize:10,fontWeight:600,marginTop:2}}>{lbl}</div>
        </div>);
      })}
    </div>
    <SectionHdr title="আজকের বাজার" action="নতুন +" onAction={()=>go("newBazar")}/>
    {BAZARS.filter(b=>b.date==="আজকে").map(b=>(
      <div key={b.id} onClick={()=>go("bazarDetail")} style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden",cursor:"pointer"}}>
        <div style={{padding:"12px 14px",display:"flex",alignItems:"center",gap:10}}>
          <Avatar label={b.wshort} bg={T.priLt} color={T.priTx} size={34}/>
          <div style={{flex:1}}>
            <div style={{fontSize:13,fontWeight:700,color:T.t1}}>{b.walletName} বাজার</div>
            <div style={{fontSize:11,color:T.t3,marginTop:1}}>{b.assigned?`${b.assigned} assigned`:"যে কেউ নিতে পারবে"} · {b.itemCount}টা item</div>
          </div>
          <Chip bg={b.status==="open"?T.ambLt:T.priLt} color={b.status==="open"?T.ambTx:T.priTx}>{b.status==="open"?"চলতেছে":"খোলা"}</Chip>
        </div>
        {b.spent>0&&<div style={{padding:"6px 14px 10px",borderTop:`0.5px solid ${T.bg3}`,fontSize:11,color:T.t3}}>মোট খরচ: <strong style={{color:T.t1}}>৳ {b.spent.toLocaleString()}</strong></div>}
      </div>
    ))}
    <SectionHdr title="দ্রুত কাজ"/>
    <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10,padding:"0 16px 8px"}}>
      {[{e:"🛒",l:"নতুন বাজার",bg:T.priLt,s:"newBazar"},{e:"💵",l:"টাকা নিলাম",bg:T.grnLt,s:"moneyEntry"},
        {e:"🧾",l:"সরাসরি খরচ",bg:T.ambLt,s:"directExpense"},{e:"📊",l:"হিসাব দেখুন",bg:T.bg3,s:"balance"}].map((q,i)=>(
        <div key={i} onClick={()=>go(q.s)} style={{display:"flex",flexDirection:"column",alignItems:"center",gap:8,
          padding:"14px 8px",background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,cursor:"pointer"}}>
          <div style={{width:44,height:44,borderRadius:14,background:q.bg,display:"flex",alignItems:"center",justifyContent:"center",fontSize:20}}>{q.e}</div>
          <span style={{fontSize:11,fontWeight:700,color:T.t2}}>{q.l}</span>
        </div>
      ))}
    </div>
    <div style={{height:12}}/>
  </div>
);

// ── SCREEN 3: Bazar List ───────────────────────────────────────────────────────
const BazarListScreen=({go})=>{
  const [f,setF]=useState("সব");
  const filters=["সব","চলতেছে","খোলা","শেষ","বাতিল"];
  const map={চলতেছে:"open",খোলা:"draft",শেষ:"closed",বাতিল:"cancelled"};
  const vis=f==="সব"?BAZARS:BAZARS.filter(b=>b.status===map[f]);
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="বাজার তালিকা" right={<span onClick={()=>go("search")} style={{color:"#fff",fontSize:20,cursor:"pointer"}}>🔍</span>}/>
      <div style={{display:"flex",gap:8,padding:"12px 16px 4px",overflowX:"auto"}}>
        {filters.map(fl=>(
          <span key={fl} onClick={()=>setF(fl)} style={{flexShrink:0,padding:"5px 12px",borderRadius:20,fontSize:12,fontWeight:700,cursor:"pointer",whiteSpace:"nowrap",
            background:f===fl?T.pri:T.bg,color:f===fl?"#fff":T.t3,border:`1px solid ${f===fl?T.pri:T.bd}`}}>{fl}</span>
        ))}
      </div>
      <Divider h={10}/>
      {["আজকে","গতকাল"].map(date=>{
        const g=vis.filter(b=>b.date===date);if(!g.length)return null;
        return(<div key={date}>
          <div style={{padding:"10px 16px 4px",fontSize:11,fontWeight:700,color:T.t4,letterSpacing:"0.05em"}}>{date}</div>
          {g.map(b=>{
            const sc={open:{bg:T.ambLt,color:T.ambTx,l:"চলতেছে"},draft:{bg:T.priLt,color:T.priTx,l:"খোলা"},closed:{bg:T.grnLt,color:T.grnTx,l:"শেষ"},cancelled:{bg:T.bg3,color:T.t3,l:"বাতিল"}};
            const s=sc[b.status]||sc.draft;
            return(<div key={b.id} onClick={()=>go("bazarDetail")} style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden",cursor:"pointer"}}>
              <div style={{padding:"12px 14px"}}>
                <div style={{display:"flex",alignItems:"center",gap:8,marginBottom:8}}>
                  <Avatar label={b.wshort} bg={T.priLt} color={T.priTx} size={28}/>
                  <span style={{fontSize:13,fontWeight:700,color:T.t1,flex:1}}>{b.walletName} বাজার</span>
                  <Chip bg={s.bg} color={s.color}>{s.l}</Chip>
                </div>
                <div style={{display:"flex",gap:20}}>
                  {b.assigned&&<div><div style={{fontSize:9,color:T.t4,fontWeight:700,letterSpacing:"0.05em"}}>ASSIGNED</div><div style={{fontSize:12,color:T.t1,fontWeight:700,marginTop:1}}>{b.assigned}</div></div>}
                  <div><div style={{fontSize:9,color:T.t4,fontWeight:700,letterSpacing:"0.05em"}}>ITEMS</div><div style={{fontSize:12,color:T.t1,fontWeight:700,marginTop:1}}>{b.itemCount}টি</div></div>
                  {b.spent>0&&<div><div style={{fontSize:9,color:T.t4,fontWeight:700,letterSpacing:"0.05em"}}>খরচ</div><div style={{fontSize:12,color:T.grn,fontWeight:700,marginTop:1}}>৳ {b.spent.toLocaleString()}</div></div>}
                </div>
              </div>
            </div>);
          })}
        </div>);
      })}
      <div style={{position:"sticky",bottom:16,display:"flex",justifyContent:"flex-end",padding:"0 16px 8px"}}>
        <div onClick={()=>go("newBazar")} style={{width:54,height:54,borderRadius:16,background:T.pri,color:"#fff",
          display:"flex",alignItems:"center",justifyContent:"center",fontSize:28,cursor:"pointer",boxShadow:"0 4px 14px rgba(21,101,192,.4)"}}>+</div>
      </div>
    </div>
  );
};

// ── SCREEN 4: Bazar Detail ─────────────────────────────────────────────────────
const BazarDetailScreen=({go,onItemTap})=>{
  const [items,setItems]=useState(INIT_ITEMS);
  const spent=items.filter(i=>i.status==="done").reduce((s,i)=>s+(i.price||0),0);
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="CEO Personal বাজার" subtitle="CEO PERSONAL WALLET" onBack={()=>go("bazarList")} right={<span style={{color:"#fff",fontSize:20,cursor:"pointer"}}>⋯</span>}/>
      <div style={{background:T.bg,padding:"10px 16px",display:"flex",alignItems:"center",gap:8,borderBottom:`0.5px solid ${T.bd}`,flexShrink:0}}>
        <Chip bg={T.ambLt} color={T.ambTx}>⏱ চলতেছে</Chip>
        <span style={{fontSize:11,color:T.t3}}>Rahim · ২৩ মে ২০২৫</span>
        <span style={{flex:1}}/>
        <span style={{fontSize:11,color:T.t4}}>৪টি item</span>
      </div>
      <SectionHdr title="আইটেম তালিকা" action="+ যোগ করুন" onAction={()=>go("addItem")}/>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
        {items.map((item,idx)=>{
          const cfg=ITEM_CFG[item.status];
          const isDone=item.status==="done",isNF=item.status==="not_found";
          return(<div key={item.id} onClick={()=>!isDone&&!isNF&&onItemTap(item,(u)=>setItems(prev=>prev.map(i=>i.id===u.id?u:i)))}
            style={{display:"flex",alignItems:"center",gap:11,padding:"11px 16px",
              borderBottom:idx<items.length-1?`0.5px solid ${T.bg2}`:"none",
              cursor:isDone||isNF?"default":"pointer",
              background:item.status==="pending"&&idx===2?"#FFFBEB":T.bg}}>
            <div style={{width:32,height:32,borderRadius:"50%",background:cfg.bg,color:cfg.color,
              display:"flex",alignItems:"center",justifyContent:"center",fontSize:14,fontWeight:700,flexShrink:0,
              border:item.status==="pending"?`1.5px dashed ${T.bd2}`:"none"}}>{cfg.icon}</div>
            <div style={{flex:1}}>
              <div style={{fontSize:13,fontWeight:700,color:isNF?T.t3:T.t1,textDecoration:isNF?"line-through":"none"}}>{item.name}</div>
              <div style={{fontSize:11,color:T.t3,marginTop:1}}>{item.qty}{item.attrs?` · ${item.attrs}`:""}</div>
            </div>
            <div style={{textAlign:"right"}}>
              {isDone&&<div style={{fontSize:13,fontWeight:700,color:T.grn}}>৳ {item.price}</div>}
              {isNF&&<Chip bg={T.redLt} color={T.redTx}>পাওয়া যায়নি</Chip>}
              {item.status==="pending"&&<Chip bg={T.ambLt} color={T.ambTx}>বাকি ✎</Chip>}
            </div>
          </div>);
        })}
      </div>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",padding:"14px 16px"}}>
        <div style={{display:"flex",justifyContent:"space-between",marginBottom:6}}><span style={{fontSize:12,color:T.t3,fontWeight:600}}>মোট খরচ</span><span style={{fontSize:14,fontWeight:800,color:T.t1}}>৳ {spent.toLocaleString()}</span></div>
        <div style={{height:"0.5px",background:T.bd,margin:"8px 0"}}/>
        <div style={{display:"flex",justifyContent:"space-between",marginBottom:4}}><span style={{fontSize:11,color:T.t3}}>Confirmed ব্যালেন্স</span><span style={{fontSize:12,fontWeight:700,color:T.grn}}>৳ ৩,২০০</span></div>
        <div style={{display:"flex",justifyContent:"space-between",marginBottom:8}}><span style={{fontSize:11,color:T.t3}}>In Progress</span><span style={{fontSize:12,fontWeight:700,color:T.amb}}>-৳ {spent}</span></div>
        <div style={{height:"0.5px",background:T.bd,margin:"0 0 8px"}}/>
        <div style={{display:"flex",justifyContent:"space-between"}}><span style={{fontSize:12,fontWeight:700,color:T.t1}}>আনুমানিক ব্যালেন্স</span><span style={{fontSize:15,fontWeight:800,color:T.grn}}>৳ {(3200-spent).toLocaleString()}</span></div>
      </div>
      <Divider/>
      <SectionHdr title="কার্যক্রমের ইতিহাস"/>
      <div style={{padding:"0 16px 4px"}}>
        {TIMELINE.map((t,i)=>(
          <div key={i} style={{display:"flex",gap:12,paddingBottom:14}}>
            <div style={{display:"flex",flexDirection:"column",alignItems:"center",flexShrink:0}}>
              <div style={{width:9,height:9,borderRadius:"50%",background:t.dot,marginTop:4}}/>
              {i<TIMELINE.length-1&&<div style={{width:1,flex:1,background:T.bd,marginTop:3}}/>}
            </div>
            <div><div style={{fontSize:12,fontWeight:700,color:T.t1}}>{t.msg}</div><div style={{fontSize:11,color:T.t3,marginTop:2}}>{t.detail}</div><div style={{fontSize:10,color:T.t4,marginTop:2}}>{t.time}</div></div>
          </div>
        ))}
      </div>
      <Divider/>
      <div style={{padding:"8px 0 4px"}}>
        <PBtn onClick={()=>go("bazarSummary")}>আজকের বাজার শেষ ✓</PBtn>
        <GBtn color={T.red} border={T.redLt}>বাতিল করুন</GBtn>
      </div>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 5: New Bazar ────────────────────────────────────────────────────────
const NewBazarScreen=({go})=>{
  const [mode,setMode]=useState("manual");
  const [rawText,setRawText]=useState("");
  const [manualItems,setManualItems]=useState([]);
  const [name,setName]=useState("");const [qty,setQty]=useState("");const [attrs,setAttrs]=useState("");
  const [showOpt,setShowOpt]=useState(false);
  const addItem=()=>{if(!name.trim())return;setManualItems(p=>[...p,{name,qty,attrs,id:Date.now()}]);setName("");setQty("");setAttrs("");setShowOpt(false);};
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="নতুন বাজার" onBack={()=>go("bazarList")}/>
      <div style={{height:12}}/>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>কোন ওয়ালেটের জন্য?</div>
      <SelectBox icon="👝" label="CEO Personal" bg={T.priLt} bdColor={T.pri} color={T.priTx}/>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>কে করবে? (optional — ফাঁকা = যে কেউ)</div>
      <SelectBox icon="👤" label="Assign করুন (optional)"/>
      <div style={{display:"flex",margin:"4px 16px 14px",background:T.bg3,borderRadius:12,padding:4}}>
        {[["manual","✏️ একে একে"],["text","📋 টেক্সট"]].map(([m,l])=>(
          <button key={m} onClick={()=>setMode(m)} style={{flex:1,padding:"9px 8px",borderRadius:9,border:"none",fontSize:12,fontWeight:700,cursor:"pointer",fontFamily:"inherit",
            background:mode===m?T.bg:"transparent",color:mode===m?T.pri:T.t3,boxShadow:mode===m?"0 1px 4px rgba(0,0,0,.08)":"none"}}>{l}</button>
        ))}
      </div>
      {mode==="manual"?<>
        <div style={{margin:"0 16px 6px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>⭐ বারবার কেনা হয়</div>
        <FreqRow onAdd={f=>{const p=f.split(" ");setManualItems(prev=>[...prev,{name:p[0],qty:p.slice(1).join(" "),attrs:"",id:Date.now()}]);}}/>
        <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>আইটেম যোগ করুন</div>
        <div style={{background:T.bg,border:`0.5px solid ${T.bd}`,borderRadius:16,margin:"0 16px 10px",padding:"12px 14px"}}>
          <input placeholder="আইটেমের নাম লিখুন…" value={name} onChange={e=>setName(e.target.value)}
            style={{width:"100%",border:`1.5px solid ${name?T.pri:T.bd}`,borderRadius:10,padding:"10px 12px",fontSize:14,color:T.t1,outline:"none",fontFamily:"inherit",marginBottom:8}}/>
          <div onClick={()=>setShowOpt(!showOpt)} style={{fontSize:12,color:T.pri,cursor:"pointer",marginBottom:8,fontWeight:600}}>
            {showOpt?"▾ কম দেখুন":"▸ পরিমাণ / ব্র্যান্ড (optional)"}
          </div>
          {showOpt&&<div style={{display:"flex",gap:8,marginBottom:8}}>
            <input placeholder="পরিমাণ যেমন: ২ কেজি" value={qty} onChange={e=>setQty(e.target.value)} style={{flex:1,border:`1.5px solid ${T.bd}`,borderRadius:10,padding:"9px 11px",fontSize:13,color:T.t1,outline:"none",fontFamily:"inherit"}}/>
            <input placeholder="ব্র্যান্ড / নোট" value={attrs} onChange={e=>setAttrs(e.target.value)} style={{flex:1,border:`1.5px solid ${T.bd}`,borderRadius:10,padding:"9px 11px",fontSize:13,color:T.t1,outline:"none",fontFamily:"inherit"}}/>
          </div>}
          <button onClick={addItem} style={{width:"100%",background:name?T.pri:T.bg3,color:name?"#fff":T.t4,border:"none",borderRadius:10,padding:"10px",fontSize:13,fontWeight:700,cursor:name?"pointer":"default",fontFamily:"inherit"}}>+ তালিকায় যোগ করুন</button>
        </div>
        {manualItems.length>0&&<div style={{background:T.bg,border:`0.5px solid ${T.bd}`,borderRadius:16,margin:"0 16px 10px",overflow:"hidden"}}>
          {manualItems.map((item,i)=>(
            <div key={item.id} style={{display:"flex",alignItems:"center",gap:10,padding:"10px 14px",borderBottom:i<manualItems.length-1?`0.5px solid ${T.bg3}`:"none"}}>
              <div style={{width:24,height:24,borderRadius:"50%",background:T.bg3,display:"flex",alignItems:"center",justifyContent:"center",fontSize:11,color:T.t4}}>{i+1}</div>
              <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:T.t1}}>{item.name}</div>{(item.qty||item.attrs)&&<div style={{fontSize:11,color:T.t3}}>{[item.qty,item.attrs].filter(Boolean).join(" · ")}</div>}</div>
              <span onClick={()=>setManualItems(p=>p.filter(x=>x.id!==item.id))} style={{fontSize:16,color:T.t4,cursor:"pointer",padding:4}}>✕</span>
            </div>
          ))}
        </div>}
      </>:<>
        <Field label="আইটেম লিস্ট লিখুন" placeholder={"দুধ ২ প্যাকেট Aarong\nগরুর মাংস ২ কেজি\nপাউরুটি ৩টা"} value={rawText} onChange={setRawText} rows={5}/>
        <div style={{margin:"-4px 16px 12px",padding:"8px 12px",background:T.priLt,borderRadius:10,fontSize:11,color:T.priTx,fontWeight:600}}>✨ Auto-parse করবে — তারপর আপনি edit করতে পারবেন</div>
        <div style={{margin:"0 16px 6px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>⭐ বারবার কেনা হয়</div>
        <FreqRow onAdd={f=>setRawText(p=>p?p+"\n"+f:f)}/>
      </>}
      <PBtn onClick={()=>go("bazarDetail")}>বাজার তৈরি করুন →</PBtn>
      <GBtn onClick={()=>go("bazarList")}>Draft সংরক্ষণ করুন</GBtn>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 6: Add Item (within bazar) ─────────────────────────────────────────
const AddItemScreen=({go})=>{
  const [name,setName]=useState("");const [qty,setQty]=useState("");
  const [unit,setUnit]=useState("");const [attrs,setAttrs]=useState("");const [note,setNote]=useState("");
  const [showOpt,setShowOpt]=useState(false);const [added,setAdded]=useState([]);
  const save=(again)=>{if(!name.trim())return;setAdded(p=>[...p,{name,qty,unit,attrs,note}]);setName("");setQty("");setUnit("");setAttrs("");setNote("");if(!again)go("bazarDetail");};
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="আইটেম যোগ করুন" subtitle="CEO PERSONAL বাজার" onBack={()=>go("bazarDetail")}/>
      <div style={{height:12}}/>
      <div style={{margin:"0 16px 6px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>⭐ বারবার কেনা হয় (এক ট্যাপে)</div>
      <FreqRow onAdd={f=>{const p=f.split(" ");setName(p[0]);setQty(p.slice(1).join(" "));}}/>
      <Divider h={4}/>
      <div style={{background:T.bg,border:`0.5px solid ${T.bd}`,borderRadius:16,margin:"10px 16px 10px",padding:"14px"}}>
        <div style={{fontSize:11,fontWeight:700,color:T.t3,marginBottom:6,letterSpacing:"0.04em"}}>আইটেমের নাম *</div>
        <input autoFocus placeholder="যেমন: গরুর মাংস, দুধ, ডিম…" value={name} onChange={e=>setName(e.target.value)}
          style={{width:"100%",border:`2px solid ${name?T.pri:T.bd}`,borderRadius:12,padding:"12px 13px",
            fontSize:16,fontWeight:600,color:T.t1,outline:"none",fontFamily:"inherit",marginBottom:10}}/>
        <div onClick={()=>setShowOpt(!showOpt)} style={{fontSize:12,color:T.pri,cursor:"pointer",fontWeight:700,marginBottom:showOpt?10:0}}>
          {showOpt?"▾ optional fields লুকান":"▸ পরিমাণ, ইউনিট, ব্র্যান্ড যোগ করুন (optional)"}
        </div>
        {showOpt&&<>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:8,marginBottom:8}}>
            <div>
              <div style={{fontSize:11,fontWeight:700,color:T.t3,marginBottom:4}}>পরিমাণ</div>
              <input placeholder="যেমন: ২, ৩০" value={qty} onChange={e=>setQty(e.target.value)} style={{width:"100%",border:`1.5px solid ${T.bd}`,borderRadius:10,padding:"9px 11px",fontSize:14,color:T.t1,outline:"none",fontFamily:"inherit"}}/>
            </div>
            <div>
              <div style={{fontSize:11,fontWeight:700,color:T.t3,marginBottom:4}}>ইউনিট</div>
              <input placeholder="কেজি, প্যাকেট, টা" value={unit} onChange={e=>setUnit(e.target.value)} style={{width:"100%",border:`1.5px solid ${T.bd}`,borderRadius:10,padding:"9px 11px",fontSize:14,color:T.t1,outline:"none",fontFamily:"inherit"}}/>
            </div>
          </div>
          <div style={{fontSize:11,fontWeight:700,color:T.t3,marginBottom:4}}>ব্র্যান্ড / অতিরিক্ত তথ্য</div>
          <input placeholder="যেমন: Aarong full cream, fresh" value={attrs} onChange={e=>setAttrs(e.target.value)} style={{width:"100%",border:`1.5px solid ${T.bd}`,borderRadius:10,padding:"9px 11px",fontSize:13,color:T.t1,outline:"none",fontFamily:"inherit",marginBottom:8}}/>
          <div style={{fontSize:11,fontWeight:700,color:T.t3,marginBottom:4}}>নোট</div>
          <input placeholder="অতিরিক্ত নির্দেশনা" value={note} onChange={e=>setNote(e.target.value)} style={{width:"100%",border:`1.5px solid ${T.bd}`,borderRadius:10,padding:"9px 11px",fontSize:13,color:T.t1,outline:"none",fontFamily:"inherit"}}/>
        </>}
      </div>
      {added.length>0&&<div style={{margin:"0 16px 10px",background:T.grnLt,borderRadius:12,padding:"10px 13px"}}>
        <div style={{fontSize:11,fontWeight:700,color:T.grnTx,marginBottom:4}}>✓ {added.length}টি যোগ হয়েছে</div>
        {added.slice(-2).map((a,i)=><div key={i} style={{fontSize:12,color:T.grnTx}}>{a.name}{a.qty?` · ${a.qty}`:""}</div>)}
      </div>}
      <div style={{display:"flex",gap:8,padding:"0 16px 8px"}}>
        <button onClick={()=>save(true)} style={{flex:1,background:name?T.bg:T.bg3,color:name?T.pri:T.t4,border:`1.5px solid ${name?T.pri:T.bd}`,borderRadius:14,padding:"12px",fontSize:13,fontWeight:700,cursor:name?"pointer":"default",fontFamily:"inherit"}}>+ আরেকটি</button>
        <button onClick={()=>save(false)} style={{flex:1,background:name?T.pri:T.bg3,color:name?"#fff":T.t4,border:"none",borderRadius:14,padding:"12px",fontSize:13,fontWeight:700,cursor:name?"pointer":"default",fontFamily:"inherit"}}>✓ শেষ করুন</button>
      </div>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 7: Direct Expense (বাজার ছাড়া সরাসরি খরচ) ─────────────────────────
const DirectExpenseScreen=({go})=>{
  const [amount,setAmount]=useState("");const [note,setNote]=useState("");const [receipt,setReceipt]=useState(false);
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="সরাসরি খরচ" subtitle="BAZAR ছাড়া খরচ" onBack={()=>go("home")}/>
      <div style={{margin:"12px 16px",background:T.ambLt,borderRadius:12,padding:"10px 13px",border:`1px solid ${T.ambTx+"30"}`}}>
        <div style={{fontSize:12,fontWeight:700,color:T.ambTx}}>ℹ️ এটি Bazar তালিকা ছাড়া সরাসরি খরচ।</div>
        <div style={{fontSize:11,color:T.ambTx,marginTop:2}}>যেমন: রিকশাভাড়া, টুকটাক কেনাকাটা।</div>
      </div>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>কোন ওয়ালেট?</div>
      <SelectBox icon="👝" label="CEO Personal" bg={T.priLt} bdColor={T.pri} color={T.priTx}/>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>পরিমাণ (৳)</div>
      <input value={amount} onChange={e=>setAmount(e.target.value)} type="number" placeholder="০"
        style={{margin:"0 16px 12px",border:`2px solid ${amount?T.pri:T.bd}`,borderRadius:12,padding:"12px 14px",
          fontSize:30,fontWeight:800,color:T.t1,outline:"none",fontFamily:"inherit",background:T.bg,width:"calc(100% - 32px)"}}/>
      <Field label="খরচের বিবরণ" placeholder="যেমন: রিকশাভাড়া, বাজারের ব্যাগ" value={note} onChange={setNote}/>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>তারিখ</div>
      <SelectBox icon="📅" label="২৩ মে ২০২৫"/>
      <div style={{margin:"0 16px 12px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>রসিদ / ছবি (optional)</div>
      <div onClick={()=>setReceipt(!receipt)} style={{margin:"0 16px 12px",background:receipt?T.grnLt:T.bg,
        border:`2px dashed ${receipt?T.grn:T.bd2}`,borderRadius:16,padding:"20px",
        display:"flex",flexDirection:"column",alignItems:"center",gap:8,cursor:"pointer"}}>
        <span style={{fontSize:28}}>{receipt?"✓":"📷"}</span>
        <span style={{fontSize:13,fontWeight:700,color:receipt?T.grn:T.t3}}>{receipt?"রসিদ যোগ হয়েছে":"ছবি দিন (tap করুন)"}</span>
        <span style={{fontSize:11,color:receipt?T.grn:T.t4}}>{receipt?"Demo: ছবি uploaded":"Camera বা Gallery থেকে"}</span>
      </div>
      <PBtn onClick={()=>go("home")} color={amount?T.pri:T.bd2}>সংরক্ষণ করুন</PBtn>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 8: Bazar Closed Summary ────────────────────────────────────────────
const BazarSummaryScreen=({go})=>(
  <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
    <div style={{background:T.grnSolid,padding:"24px 16px 20px"}}>
      <div style={{textAlign:"center"}}>
        <div style={{fontSize:48,marginBottom:8}}>✅</div>
        <div style={{color:"#fff",fontSize:20,fontWeight:800}}>বাজার শেষ হয়েছে!</div>
        <div style={{color:"rgba(255,255,255,.8)",fontSize:13,marginTop:4}}>CEO Personal · ২৩ মে ২০২৫</div>
      </div>
    </div>
    <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:10,padding:"16px 16px 4px"}}>
      {[{l:"কেনা হয়েছে",v:"২টি",bg:T.grnLt,c:T.grnTx},{l:"পাওয়া যায়নি",v:"১টি",bg:T.redLt,c:T.redTx},{l:"মোট খরচ",v:"৳ ১৮০",bg:T.priLt,c:T.priTx}].map((s,i)=>(
        <div key={i} style={{background:s.bg,borderRadius:14,padding:"12px 10px",textAlign:"center"}}>
          <div style={{fontSize:16,fontWeight:800,color:s.c}}>{s.v}</div>
          <div style={{fontSize:10,fontWeight:700,color:s.c,opacity:.8,marginTop:3}}>{s.l}</div>
        </div>
      ))}
    </div>
    <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"10px 16px",padding:"14px 16px"}}>
      <div style={{fontSize:13,fontWeight:700,color:T.t1,marginBottom:10}}>ব্যালেন্স আপডেট</div>
      <div style={{display:"flex",justifyContent:"space-between",marginBottom:6}}>
        <span style={{fontSize:12,color:T.t3}}>আগের ব্যালেন্স</span>
        <span style={{fontSize:12,fontWeight:600,color:T.t1}}>৳ ৩,২০০</span>
      </div>
      <div style={{display:"flex",justifyContent:"space-between",marginBottom:6}}>
        <span style={{fontSize:12,color:T.t3}}>এই বাজারের খরচ</span>
        <span style={{fontSize:12,fontWeight:600,color:T.red}}>-৳ ১৮০</span>
      </div>
      <div style={{height:"0.5px",background:T.bd,margin:"8px 0"}}/>
      <div style={{display:"flex",justifyContent:"space-between"}}>
        <span style={{fontSize:13,fontWeight:700,color:T.t1}}>নতুন ব্যালেন্স</span>
        <span style={{fontSize:15,fontWeight:800,color:T.grn}}>৳ ৩,০২০</span>
      </div>
    </div>
    <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
      <div style={{padding:"12px 14px",fontSize:13,fontWeight:700,color:T.t1,borderBottom:`0.5px solid ${T.bg3}`}}>আইটেম সারাংশ</div>
      {INIT_ITEMS.map((item,i)=>{
        const cfg=ITEM_CFG[item.status];
        return(<div key={i} style={{display:"flex",alignItems:"center",gap:10,padding:"10px 14px",borderBottom:i<INIT_ITEMS.length-1?`0.5px solid ${T.bg3}`:"none"}}>
          <div style={{width:24,height:24,borderRadius:"50%",background:cfg.bg,color:cfg.color,display:"flex",alignItems:"center",justifyContent:"center",fontSize:11,fontWeight:700}}>{cfg.icon}</div>
          <span style={{flex:1,fontSize:12,fontWeight:600,color:item.status==="not_found"?T.t3:T.t1,textDecoration:item.status==="not_found"?"line-through":"none"}}>{item.name}</span>
          {item.price&&<span style={{fontSize:12,fontWeight:700,color:T.grn}}>৳ {item.price}</span>}
          {item.status==="not_found"&&<Chip bg={T.redLt} color={T.redTx}>পাওয়া যায়নি</Chip>}
        </div>);
      })}
    </div>
    <PBtn onClick={()=>go("newBazar")}>+ আরেকটি বাজার শুরু করুন</PBtn>
    <GBtn onClick={()=>go("home")}>হোমে ফিরুন</GBtn>
    <div style={{height:8}}/>
  </div>
);

// ── SCREEN 9: Balance ──────────────────────────────────────────────────────────
const BalanceScreen=({go})=>(
  <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
    <AppBar title="হিসাব / ব্যালেন্স" right={<span style={{color:"#fff",fontSize:18}}>📅</span>}/>
    <div style={{display:"flex",gap:8,padding:"12px 16px 4px",overflowX:"auto"}}>
      {["সব ওয়ালেট","Rahim","Karim"].map((f,i)=>(
        <span key={f} style={{flexShrink:0,padding:"5px 12px",borderRadius:20,fontSize:12,fontWeight:700,cursor:"pointer",whiteSpace:"nowrap",
          background:i===0?T.pri:T.bg,color:i===0?"#fff":T.t3,border:`1px solid ${i===0?T.pri:T.bd}`}}>{f}</span>
      ))}
    </div>
    <Divider h={12}/>
    {WALLETS.map(w=>{
      const bg=w.pos===null?T.neu:w.pos?T.grnSolid:T.redSolid;
      const lbl=w.pos===null?"হিসাব মিলে গেছে ✓":w.pos?"হাতে আছে":"পাওনা আছে — দিতে হবে";
      return(<div key={w.id} onClick={()=>go("walletDetail")} style={{background:bg,borderRadius:20,padding:"18px",margin:"0 16px 12px",cursor:"pointer"}}>
        <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:12}}>
          <div style={{fontSize:11,fontWeight:800,color:"rgba(255,255,255,.75)",letterSpacing:"0.06em"}}>{w.name.toUpperCase()}</div>
          <Chip bg="rgba(255,255,255,.18)" color="rgba(255,255,255,.9)" style={{fontSize:10}}>Rahim</Chip>
        </div>
        <div style={{fontSize:28,fontWeight:900,color:"#fff",letterSpacing:"-0.5px"}}>৳ {Math.abs(w.balance).toLocaleString()}</div>
        <div style={{fontSize:11,color:"rgba(255,255,255,.75)",marginTop:4,fontWeight:600}}>{lbl}</div>
        {w.pos!==null&&<><div style={{height:"0.5px",background:"rgba(255,255,255,.2)",margin:"12px 0"}}/>
        <div style={{display:"flex",gap:20}}>
          <div><div style={{fontSize:9,color:"rgba(255,255,255,.6)",fontWeight:700,letterSpacing:"0.05em"}}>CONFIRMED</div><div style={{fontSize:13,color:"#fff",fontWeight:700,marginTop:2}}>৳ {Math.abs(w.confirmed)}</div></div>
          <div><div style={{fontSize:9,color:"rgba(255,255,255,.6)",fontWeight:700,letterSpacing:"0.05em"}}>IN PROGRESS</div><div style={{fontSize:13,color:"rgba(255,255,255,.8)",fontWeight:700,marginTop:2}}>৳ {Math.abs(w.inprogress)}</div></div>
        </div></>}
      </div>);
    })}
    <PBtn onClick={()=>go("moneyEntry")} style={{margin:"4px 16px 12px"}}>+ টাকার এন্ট্রি করুন</PBtn>
  </div>
);

// ── SCREEN 10: Money Entry ─────────────────────────────────────────────────────
const MoneyEntryScreen=({go})=>{
  const [type,setType]=useState("received");const [amount,setAmount]=useState("");const [note,setNote]=useState("");
  const tConf={received:{label:"টাকা নিলাম",bg:T.grnLt,color:T.grnTx,desc:"Assistant টাকা নিয়েছে"},returned:{label:"টাকা ফেরত দিলাম",bg:T.redLt,color:T.redTx,desc:"Unused টাকা ফেরত"},adjust:{label:"সমন্বয়",bg:T.ambLt,color:T.ambTx,desc:"Admin correction — note আবশ্যক"}};
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="টাকা এন্ট্রি" onBack={()=>go("home")}/>
      <div style={{height:14}}/>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>এন্ট্রির ধরন</div>
      <div style={{margin:"0 16px 12px",display:"flex",flexDirection:"column",gap:8}}>
        {Object.entries(tConf).map(([k,v])=>(
          <div key={k} onClick={()=>setType(k)} style={{display:"flex",alignItems:"center",gap:12,padding:"11px 14px",
            background:type===k?v.bg:T.bg,borderRadius:12,border:`1.5px solid ${type===k?v.color:T.bd}`,cursor:"pointer"}}>
            <div style={{width:20,height:20,borderRadius:"50%",border:`2px solid ${v.color}`,background:type===k?v.color:"transparent",display:"flex",alignItems:"center",justifyContent:"center"}}>
              {type===k&&<div style={{width:8,height:8,borderRadius:"50%",background:"#fff"}}/>}
            </div>
            <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:T.t1}}>{v.label}</div><div style={{fontSize:11,color:T.t3}}>{v.desc}</div></div>
          </div>
        ))}
      </div>
      <SelectBox icon="👝" label="CEO Personal" bg={T.priLt} bdColor={T.pri} color={T.priTx}/>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>সহকারী</div>
      <div style={{margin:"0 16px 12px",background:T.bg,border:`1.5px solid ${T.bd}`,borderRadius:12,padding:"11px 14px",display:"flex",alignItems:"center",gap:10}}>
        <Avatar label="R" bg={T.priLt} color={T.priTx} size={28}/><span style={{fontSize:14,fontWeight:700,color:T.t1,flex:1}}>Rahim</span><span style={{fontSize:16,color:T.t3}}>▾</span>
      </div>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>পরিমাণ (৳)</div>
      <input value={amount} onChange={e=>setAmount(e.target.value)} type="number" placeholder="০"
        style={{margin:"0 16px 12px",border:`2px solid ${amount?T.pri:T.bd}`,borderRadius:12,padding:"12px 14px",fontSize:28,fontWeight:800,color:T.t1,outline:"none",fontFamily:"inherit",background:T.bg,width:"calc(100% - 32px)"}}/>
      <Field label="নোট" placeholder={type==="adjust"?"সমন্বয়ের কারণ লিখুন (আবশ্যক)":"optional"} value={note} onChange={setNote}/>
      <SelectBox icon="📅" label="২৩ মে ২০২৫"/>
      <PBtn onClick={()=>go("home")}>সংরক্ষণ করুন</PBtn>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 11: Notifications ───────────────────────────────────────────────────
const NotificationsScreen=({go})=>{
  const [notifs,setNotifs]=useState([
    {id:1,read:false,icon:"🛒",title:"Rahim CEO Personal বাজার শুরু করেছে",sub:"৪টি item যোগ করা হয়েছে",time:"১০ মিনিট আগে",color:T.ambLt},
    {id:2,read:false,icon:"✕",title:"গরুর মাংস পাওয়া যায়নি",sub:"CEO Personal বাজার · Rahim",time:"১৫ মিনিট আগে",color:T.redLt},
    {id:3,read:false,icon:"💵",title:"Accounts Rahim-কে ৳ ৫,০০০ দিয়েছে",sub:"Office Wallet · Karim (Accounts)",time:"১ ঘণ্টা আগে",color:T.grnLt},
    {id:4,read:true,icon:"✓",title:"Rahim Office Wallet বাজার শেষ করেছে",sub:"মোট খরচ ৳ ৩,২০০",time:"গতকাল ১১:৩০ AM",color:T.grnLt},
    {id:5,read:true,icon:"📅",title:"এপ্রিলের হিসাব বন্ধ হয়েছে",sub:"Accounts Officer · Balance: ৳ ৮০০",time:"৩০ এপ্রিল",color:T.priLt},
    {id:6,read:true,icon:"⚠️",title:"CEO Personal ব্যালেন্স নেগেটিভ হয়েছে",sub:"Rahim পাবে ৳ ১,২০০",time:"২২ মে",color:T.redLt},
  ]);
  const unread=notifs.filter(n=>!n.read).length;
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="নোটিফিকেশন" right={unread>0?<span onClick={()=>setNotifs(p=>p.map(n=>({...n,read:true})))} style={{color:"rgba(255,255,255,.85)",fontSize:12,fontWeight:700,cursor:"pointer"}}>সব পড়া ✓</span>:null}/>
      {unread>0&&<div style={{background:T.priLt,padding:"8px 16px",display:"flex",alignItems:"center",gap:8}}>
        <div style={{width:8,height:8,borderRadius:"50%",background:T.pri}}/>
        <span style={{fontSize:12,fontWeight:700,color:T.priTx}}>{unread}টি নতুন নোটিফিকেশন</span>
      </div>}
      {["আজকে","গতকাল","আগে"].map(group=>{
        const g=notifs.filter(n=>group==="আজকে"?n.time.includes("মিনিট")||n.time.includes("ঘণ্টা"):group==="গতকাল"?n.time.includes("গতকাল"):!n.time.includes("মিনিট")&&!n.time.includes("ঘণ্টা")&&!n.time.includes("গতকাল"));
        if(!g.length)return null;
        return(<div key={group}>
          <div style={{padding:"10px 16px 4px",fontSize:11,fontWeight:700,color:T.t4,letterSpacing:"0.05em"}}>{group}</div>
          <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
            {g.map((n,i)=>(
              <div key={n.id} onClick={()=>setNotifs(p=>p.map(x=>x.id===n.id?{...x,read:true}:x))}
                style={{display:"flex",alignItems:"flex-start",gap:12,padding:"12px 14px",
                  borderBottom:i<g.length-1?`0.5px solid ${T.bg3}`:"none",background:n.read?T.bg:T.bg2,cursor:"pointer"}}>
                <div style={{width:36,height:36,borderRadius:12,background:n.color,display:"flex",alignItems:"center",justifyContent:"center",fontSize:16,flexShrink:0}}>{n.icon}</div>
                <div style={{flex:1}}>
                  <div style={{fontSize:12,fontWeight:n.read?600:700,color:T.t1,lineHeight:1.4}}>{n.title}</div>
                  <div style={{fontSize:11,color:T.t3,marginTop:2}}>{n.sub}</div>
                  <div style={{fontSize:10,color:T.t4,marginTop:3}}>{n.time}</div>
                </div>
                {!n.read&&<div style={{width:8,height:8,borderRadius:"50%",background:T.pri,flexShrink:0,marginTop:4}}/>}
              </div>
            ))}
          </div>
        </div>);
      })}
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 12: Reports ─────────────────────────────────────────────────────────
const ReportsScreen=({go})=>{
  const [month,setMonth]=useState("মে ২০২৫");
  const d={received:18000,spent:15200,returned:1200,wallets:[{name:"Office Wallet",received:10000,spent:8500,balance:800},{name:"CEO Personal",received:5000,spent:5850,balance:-1200},{name:"CTO Personal",received:3000,spent:2850,balance:0}],topItems:[{name:"গরুর মাংস",total:4200,count:8},{name:"মুরগি",total:3100,count:7},{name:"চাল",total:2100,count:3},{name:"দুধ",total:1560,count:26}]};
  const net=d.received-d.spent-d.returned;const maxS=Math.max(...d.wallets.map(w=>w.spent));
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="রিপোর্ট" right={<span style={{color:"rgba(255,255,255,.85)",fontSize:12,fontWeight:700,cursor:"pointer"}}>Export ↓</span>}/>
      <div style={{display:"flex",gap:8,padding:"12px 16px 4px",overflowX:"auto"}}>
        {["মার্চ ২০২৫","এপ্রিল ২০২৫","মে ২০২৫"].map(m=>(
          <span key={m} onClick={()=>setMonth(m)} style={{flexShrink:0,padding:"5px 12px",borderRadius:20,fontSize:12,fontWeight:700,cursor:"pointer",whiteSpace:"nowrap",
            background:month===m?T.pri:T.bg,color:month===m?"#fff":T.t3,border:`1px solid ${month===m?T.pri:T.bd}`}}>{m}</span>
        ))}
      </div>
      <SectionHdr title="মাসের সারসংক্ষেপ"/>
      <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10,padding:"0 16px 4px"}}>
        {[{l:"মোট প্রাপ্তি",v:d.received,c:T.grn,bg:T.grnLt},{l:"মোট খরচ",v:d.spent,c:T.red,bg:T.redLt},
          {l:"ফেরত দেওয়া",v:d.returned,c:T.amb,bg:T.ambLt},{l:"নিট ব্যালেন্স",v:net,c:net>=0?T.grn:T.red,bg:net>=0?T.grnLt:T.redLt}].map((s,i)=>(
          <div key={i} style={{background:s.bg,borderRadius:14,padding:"12px 14px"}}>
            <div style={{fontSize:9,fontWeight:700,color:s.c,letterSpacing:"0.04em",marginBottom:6,opacity:.85}}>{s.l.toUpperCase()}</div>
            <div style={{fontSize:18,fontWeight:800,color:s.c}}>৳ {Math.abs(s.v).toLocaleString()}</div>
          </div>
        ))}
      </div>
      <SectionHdr title="ওয়ালেট বিভাজন"/>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",padding:"14px"}}>
        {d.wallets.map((w,i)=>(
          <div key={i} style={{marginBottom:i<d.wallets.length-1?14:0}}>
            <div style={{display:"flex",justifyContent:"space-between",marginBottom:5}}>
              <span style={{fontSize:12,fontWeight:700,color:T.t1}}>{w.name}</span>
              <span style={{fontSize:12,fontWeight:700,color:w.balance>=0?T.grn:T.red}}>{w.balance>=0?"+":"-"}৳ {Math.abs(w.balance).toLocaleString()}</span>
            </div>
            <div style={{height:8,background:T.bg3,borderRadius:4,overflow:"hidden"}}>
              <div style={{height:"100%",width:`${(w.spent/maxS)*100}%`,background:w.balance>=0?T.grn:T.red,borderRadius:4}}/>
            </div>
            <div style={{display:"flex",justifyContent:"space-between",marginTop:4}}>
              <span style={{fontSize:10,color:T.t4}}>খরচ ৳ {w.spent.toLocaleString()}</span>
              <span style={{fontSize:10,color:T.t4}}>নিলাম ৳ {w.received.toLocaleString()}</span>
            </div>
          </div>
        ))}
      </div>
      <SectionHdr title="বেশি কেনা আইটেম"/>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
        {d.topItems.map((item,i)=>(
          <div key={i} style={{display:"flex",alignItems:"center",gap:12,padding:"11px 14px",borderBottom:i<d.topItems.length-1?`0.5px solid ${T.bg3}`:"none"}}>
            <div style={{width:28,height:28,borderRadius:8,background:T.bg3,display:"flex",alignItems:"center",justifyContent:"center",fontSize:13,fontWeight:800,color:T.t3}}>{i+1}</div>
            <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:T.t1}}>{item.name}</div><div style={{fontSize:11,color:T.t3}}>{item.count}বার</div></div>
            <div style={{fontSize:13,fontWeight:700,color:T.grn}}>৳ {item.total.toLocaleString()}</div>
          </div>
        ))}
      </div>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 13: Wallet Detail ───────────────────────────────────────────────────
const WalletDetailScreen=({go})=>{
  const entries=[
    {type:"money_received",amount:5000,from:"CEO",date:"২০ মে",note:"মাসের advance",locked:false},
    {type:"expense",amount:-3800,from:"Rahim",date:"২১ মে",note:"CEO বাজার শেষ",locked:false},
    {type:"money_received",amount:3000,from:"CEO",date:"১৫ মে",note:"",locked:true},
    {type:"expense",amount:-2450,from:"Karim",date:"১৪ মে",note:"CTO বাজার",locked:true},
    {type:"money_returned",amount:-250,from:"Rahim",date:"১০ মে",note:"বাজার শেষে বাকি",locked:true},
  ];
  const tC={money_received:{label:"টাকা নিলাম",color:T.grn,bg:T.grnLt,sign:"+",e:"💵"},expense:{label:"বাজার খরচ",color:T.red,bg:T.redLt,sign:"-",e:"🛒"},money_returned:{label:"ফেরত দিলাম",color:T.amb,bg:T.ambLt,sign:"-",e:"↩️"}};
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="CEO Personal" subtitle="WALLET DETAIL" onBack={()=>go("balance")} right={<span style={{color:"rgba(255,255,255,.8)",fontSize:18}}>⋯</span>}/>
      <div style={{background:T.redSolid,padding:"18px 16px"}}>
        <div style={{display:"flex",alignItems:"flex-start",justifyContent:"space-between"}}>
          <div><div style={{color:"rgba(255,255,255,.75)",fontSize:11,fontWeight:700,letterSpacing:"0.05em",marginBottom:6}}>পাওনা আছে</div><div style={{color:"#fff",fontSize:28,fontWeight:900,letterSpacing:"-0.5px"}}>৳ ১,২০০</div></div>
          <div style={{textAlign:"right"}}><div style={{fontSize:10,color:"rgba(255,255,255,.7)",fontWeight:700,marginBottom:4}}>Owner</div><div style={{color:"rgba(255,255,255,.9)",fontSize:12,fontWeight:700}}>CEO</div></div>
        </div>
        <div style={{height:"0.5px",background:"rgba(255,255,255,.2)",margin:"12px 0"}}/>
        <div style={{display:"flex",gap:20}}>
          <div><div style={{fontSize:9,color:"rgba(255,255,255,.65)",fontWeight:700,letterSpacing:"0.05em"}}>CONFIRMED</div><div style={{fontSize:13,color:"#fff",fontWeight:700,marginTop:2}}>-৳ ৩৫০</div></div>
          <div><div style={{fontSize:9,color:"rgba(255,255,255,.65)",fontWeight:700,letterSpacing:"0.05em"}}>IN PROGRESS</div><div style={{fontSize:13,color:"rgba(255,255,255,.8)",fontWeight:700,marginTop:2}}>-৳ ৮৫০</div></div>
          <div><div style={{fontSize:9,color:"rgba(255,255,255,.65)",fontWeight:700,letterSpacing:"0.05em"}}>ASSISTANT</div><div style={{fontSize:13,color:"rgba(255,255,255,.8)",fontWeight:700,marginTop:2}}>Rahim</div></div>
        </div>
      </div>
      <SectionHdr title="লেনদেনের ইতিহাস" action="+ টাকা এন্ট্রি" onAction={()=>go("moneyEntry")}/>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
        {entries.map((e,i)=>{
          const c=tC[e.type];
          return(<div key={i} style={{display:"flex",alignItems:"center",gap:12,padding:"11px 14px",borderBottom:i<entries.length-1?`0.5px solid ${T.bg3}`:"none"}}>
            <div style={{width:34,height:34,borderRadius:10,background:c.bg,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,fontSize:14}}>{c.e}</div>
            <div style={{flex:1}}>
              <div style={{fontSize:12,fontWeight:700,color:T.t1}}>{c.label}</div>
              <div style={{fontSize:11,color:T.t3,marginTop:1}}>{e.from} · {e.date}{e.note?` · ${e.note}`:""}</div>
            </div>
            <div style={{textAlign:"right"}}>
              <div style={{fontSize:13,fontWeight:800,color:c.color}}>{c.sign}৳ {Math.abs(e.amount).toLocaleString()}</div>
              {e.locked&&<span style={{fontSize:9,color:T.t4,fontWeight:700}}>🔒 LOCKED</span>}
            </div>
          </div>);
        })}
      </div>
      <PBtn onClick={()=>go("monthlyClose")}>মাসের হিসাব বন্ধ করুন →</PBtn>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 14: Monthly Close ───────────────────────────────────────────────────
const MonthlyCloseScreen=({go})=>{
  const [step,setStep]=useState(1);
  const sum=[{w:"Office Wallet",r:10000,s:8500,b:800},{w:"CEO Personal",r:5000,s:5850,b:-1200},{w:"CTO Personal",r:3000,s:2850,b:0}];
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="হিসাব বন্ধ" subtitle="মে ২০২৫" onBack={()=>go("walletDetail")}/>
      <div style={{display:"flex",alignItems:"center",padding:"14px 16px",gap:0}}>
        {[1,2,3].map((s,i)=>(
          <div key={s} style={{display:"flex",alignItems:"center",flex:i<2?1:0}}>
            <div style={{width:28,height:28,borderRadius:"50%",flexShrink:0,background:step>=s?T.pri:T.bg3,color:step>=s?"#fff":T.t4,display:"flex",alignItems:"center",justifyContent:"center",fontSize:12,fontWeight:800,border:step>=s?"none":`1.5px solid ${T.bd2}`}}>
              {step>s?"✓":s}
            </div>
            {i<2&&<div style={{flex:1,height:2,background:step>s?T.pri:T.bg3,margin:"0 4px"}}/>}
          </div>
        ))}
      </div>
      <div style={{display:"flex",justifyContent:"space-between",padding:"0 16px 14px"}}>
        {["রিভিউ","নিশ্চিত","সম্পন্ন"].map((l,i)=><span key={i} style={{fontSize:10,fontWeight:700,color:step>i?T.pri:T.t4,letterSpacing:"0.03em"}}>{l}</span>)}
      </div>
      {step===1&&<>
        <div style={{background:T.ambLt,margin:"0 16px 12px",borderRadius:14,padding:"12px 14px"}}>
          <div style={{fontSize:12,fontWeight:700,color:T.ambTx,marginBottom:4}}>⚠️ গুরুত্বপূর্ণ সতর্কতা</div>
          <div style={{fontSize:11,color:T.ambTx,lineHeight:1.5}}>মে ২০২৫ বন্ধ হলে এই মাসের সব entry permanently lock হবে। কেউ আর edit করতে পারবে না।</div>
        </div>
        <SectionHdr title="মে ২০২৫ ব্যালেন্স সারাংশ"/>
        <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 12px",overflow:"hidden"}}>
          <div style={{display:"grid",gridTemplateColumns:"2fr 1.2fr 1.2fr 1.2fr",padding:"8px 14px",background:T.bg3}}>
            {["ওয়ালেট","নিলাম","খরচ","ব্যালেন্স"].map(h=><div key={h} style={{fontSize:10,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>{h}</div>)}
          </div>
          {sum.map((r,i)=>(
            <div key={i} style={{display:"grid",gridTemplateColumns:"2fr 1.2fr 1.2fr 1.2fr",padding:"10px 14px",borderTop:`0.5px solid ${T.bg3}`}}>
              <div style={{fontSize:11,fontWeight:700,color:T.t1}}>{r.w.split(" ")[0]}</div>
              <div style={{fontSize:11,color:T.grn,fontWeight:600}}>৳{(r.r/1000).toFixed(0)}k</div>
              <div style={{fontSize:11,color:T.red,fontWeight:600}}>৳{(r.s/1000).toFixed(0)}k</div>
              <div style={{fontSize:11,fontWeight:800,color:r.b>=0?T.grn:T.red}}>{r.b>=0?"":"-"}৳{Math.abs(r.b)}</div>
            </div>
          ))}
        </div>
        <PBtn onClick={()=>setStep(2)}>পরবর্তী ধাপ →</PBtn>
      </>}
      {step===2&&<>
        <div style={{background:T.bg,border:`0.5px solid ${T.bd}`,borderRadius:16,margin:"0 16px 14px",padding:"16px"}}>
          <div style={{fontSize:13,fontWeight:700,color:T.t1,marginBottom:10}}>নিশ্চিত করুন</div>
          {["সব entry রিভিউ করেছি","সব assistant-এর balance সঠিক আছে","কোনো pending correction নেই"].map((item,i)=>(
            <div key={i} style={{display:"flex",alignItems:"center",gap:10,marginBottom:i<2?10:0}}>
              <div style={{width:20,height:20,borderRadius:6,background:T.grnLt,border:`1.5px solid ${T.grn}`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:12,color:T.grn}}>✓</div>
              <span style={{fontSize:12,color:T.t2,fontWeight:600}}>{item}</span>
            </div>
          ))}
        </div>
        <div style={{margin:"0 16px 16px",padding:"12px 14px",background:T.redLt,borderRadius:12}}>
          <div style={{fontSize:11,fontWeight:700,color:T.redTx}}>⚠️ এই কাজ পূর্বাবস্থায় ফেরানো যাবে না।</div>
        </div>
        <PBtn color={T.grnSolid} onClick={()=>setStep(3)}>✓ মে ২০২৫ হিসাব বন্ধ করুন</PBtn>
        <GBtn onClick={()=>setStep(1)}>← ফিরে যান</GBtn>
      </>}
      {step===3&&<div style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",padding:"0 32px"}}>
        <div style={{fontSize:56,marginBottom:16}}>✅</div>
        <div style={{fontSize:18,fontWeight:800,color:T.t1,textAlign:"center",marginBottom:8}}>মে ২০২৫ হিসাব বন্ধ হয়েছে</div>
        <div style={{fontSize:13,color:T.t3,textAlign:"center",lineHeight:1.6,marginBottom:24}}>সব entry lock হয়ে গেছে। Snapshot সংরক্ষিত হয়েছে।</div>
        <Chip bg={T.grnLt} color={T.grnTx} style={{fontSize:12,padding:"6px 14px"}}>🔒 Locked · মে ২০২৫</Chip>
        <div style={{marginTop:24,width:"100%"}}><PBtn onClick={()=>go("reports")}>রিপোর্ট দেখুন</PBtn></div>
      </div>}
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 15: Admin Panel ─────────────────────────────────────────────────────
const AdminScreen=({go})=>{
  const [tab,setTab]=useState("users");
  const users=[
    {name:"Rahim Uddin",phone:"01711-XXXXXX",role:"assistant",active:true},
    {name:"Karim Sheikh",phone:"01812-XXXXXX",role:"assistant",active:true},
    {name:"Mr. CEO",phone:"01900-XXXXXX",role:"owner",active:true},
    {name:"Mr. CTO",phone:"01901-XXXXXX",role:"owner",active:true},
    {name:"Fatema (Accounts)",phone:"01613-XXXXXX",role:"owner",active:true},
    {name:"Sabbir Ahmed",phone:"01714-XXXXXX",role:"assistant",active:false},
  ];
  const wallets=[{name:"Office Wallet",type:"shared",owners:["Fatema"],balance:800},{name:"CEO Personal",type:"personal",owners:["CEO"],balance:-1200},{name:"CTO Personal",type:"personal",owners:["CTO"],balance:0}];
  const rC={admin:{bg:T.redLt,color:T.redTx},owner:{bg:T.priLt,color:T.priTx},assistant:{bg:T.grnLt,color:T.grnTx}};
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="Admin Panel" right={<span style={{color:"rgba(255,255,255,.8)",fontSize:18}}>⚙</span>}/>
      <div style={{display:"flex",background:T.bg3,margin:"12px 16px",borderRadius:12,padding:4}}>
        {[["users","👥 ইউজার"],["wallets","👝 ওয়ালেট"]].map(([t,l])=>(
          <button key={t} onClick={()=>setTab(t)} style={{flex:1,padding:"9px 8px",borderRadius:9,border:"none",fontSize:12,fontWeight:700,cursor:"pointer",fontFamily:"inherit",
            background:tab===t?T.bg:"transparent",color:tab===t?T.pri:T.t3,boxShadow:tab===t?"0 1px 4px rgba(0,0,0,.08)":"none"}}>{l}</button>
        ))}
      </div>
      {tab==="users"&&<>
        <div style={{display:"flex",justifyContent:"space-between",padding:"0 16px 8px",alignItems:"center"}}>
          <span style={{fontSize:12,color:T.t3,fontWeight:600}}>{users.length}জন ইউজার</span>
          <span style={{fontSize:12,color:T.pri,fontWeight:700,cursor:"pointer"}}>+ নতুন ইউজার</span>
        </div>
        <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
          {users.map((u,i)=>{
            const rc=rC[u.role]||rC.assistant;
            return(<div key={i} style={{display:"flex",alignItems:"center",gap:11,padding:"11px 14px",
              borderBottom:i<users.length-1?`0.5px solid ${T.bg3}`:"none",opacity:u.active?1:0.5}}>
              <Avatar label={u.name.split(" ").map(n=>n[0]).join("").slice(0,2)} bg={u.active?rc.bg:T.bg3} color={u.active?rc.color:T.t4} size={34}/>
              <div style={{flex:1}}><div style={{fontSize:12,fontWeight:700,color:T.t1}}>{u.name}</div><div style={{fontSize:10,color:T.t3,marginTop:1}}>{u.phone}</div></div>
              <div style={{display:"flex",flexDirection:"column",gap:4,alignItems:"flex-end"}}>
                <Chip bg={rc.bg} color={rc.color}>{u.role}</Chip>
                {!u.active&&<span style={{fontSize:9,color:T.t4,fontWeight:700}}>INACTIVE</span>}
              </div>
            </div>);
          })}
        </div>
      </>}
      {tab==="wallets"&&<>
        <div style={{display:"flex",justifyContent:"space-between",padding:"0 16px 8px",alignItems:"center"}}>
          <span style={{fontSize:12,color:T.t3,fontWeight:600}}>{wallets.length}টি ওয়ালেট</span>
          <span style={{fontSize:12,color:T.pri,fontWeight:700,cursor:"pointer"}}>+ নতুন ওয়ালেট</span>
        </div>
        <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
          {wallets.map((w,i)=>(
            <div key={i} style={{padding:"12px 14px",borderBottom:i<wallets.length-1?`0.5px solid ${T.bg3}`:"none"}}>
              <div style={{display:"flex",alignItems:"center",gap:8,marginBottom:8}}>
                <Avatar label={w.name.split(" ").map(n=>n[0]).join("").slice(0,2)} bg={T.priLt} color={T.priTx} size={30}/>
                <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:T.t1}}>{w.name}</div><div style={{fontSize:10,color:T.t3}}>{w.type}</div></div>
                <div style={{fontSize:13,fontWeight:800,color:w.balance>=0?T.grn:T.red}}>{w.balance>=0?"":"-"}৳{Math.abs(w.balance).toLocaleString()}</div>
              </div>
              <div style={{display:"flex",gap:6,flexWrap:"wrap"}}>
                <span style={{fontSize:10,color:T.t3}}>Owner:</span>
                {w.owners.map(o=><Chip key={o} bg={T.priLt} color={T.priTx} style={{fontSize:10,padding:"2px 7px"}}>{o}</Chip>)}
              </div>
            </div>
          ))}
        </div>
      </>}
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 16: Search ──────────────────────────────────────────────────────────
const SearchScreen=({go})=>{
  const [q,setQ]=useState("");const [tab,setTab]=useState("বাজার");
  const results={
    বাজার:[{icon:"🛒",title:"CEO Personal বাজার",sub:"Rahim · ২৩ মে · চলতেছে",chip:{bg:T.ambLt,c:T.ambTx,l:"চলতেছে"}},{icon:"🛒",title:"Office Lunch বাজার",sub:"Karim · ২২ মে · শেষ",chip:{bg:T.grnLt,c:T.grnTx,l:"শেষ"}}],
    আইটেম:[{icon:"🥚",title:"ডিম ৩০টা",sub:"CEO Personal বাজার · ২৩ মে · বাকি",chip:{bg:T.ambLt,c:T.ambTx,l:"বাকি"}},{icon:"🥛",title:"দুধ ২ প্যাকেট",sub:"Office Lunch · ২২ মে · কেনা",chip:{bg:T.grnLt,c:T.grnTx,l:"কেনা"}}],
    টাকা:[{icon:"💵",title:"৳ ৫,০০০ নিলাম",sub:"Rahim · CEO Personal · ২০ মে",chip:{bg:T.grnLt,c:T.grnTx,l:"নিলাম"}},{icon:"↩️",title:"৳ ২৫০ ফেরত",sub:"Rahim · Office · ১০ মে",chip:{bg:T.ambLt,c:T.ambTx,l:"ফেরত"}}],
  };
  const recent=["CEO Personal","গরুর মাংস","Rahim","দুধ"];
  const list=q?results[tab]:[];
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <div style={{background:T.pri,padding:"12px 16px",display:"flex",alignItems:"center",gap:10}}>
        <span onClick={()=>go("bazarList")} style={{color:"#fff",fontSize:22,cursor:"pointer",lineHeight:1}}>←</span>
        <div style={{flex:1,background:"rgba(255,255,255,.15)",borderRadius:12,padding:"9px 13px",display:"flex",alignItems:"center",gap:8}}>
          <span style={{fontSize:16}}>🔍</span>
          <input autoFocus value={q} onChange={e=>setQ(e.target.value)} placeholder="বাজার, আইটেম, বা টাকা খুঁজুন…"
            style={{flex:1,background:"transparent",border:"none",outline:"none",color:"#fff",fontSize:14,fontFamily:"inherit"}}/>
          {q&&<span onClick={()=>setQ("")} style={{color:"rgba(255,255,255,.7)",cursor:"pointer",fontSize:18,lineHeight:1}}>✕</span>}
        </div>
      </div>
      <div style={{display:"flex",gap:8,padding:"12px 16px 4px",overflowX:"auto"}}>
        {["বাজার","আইটেম","টাকা"].map(t=>(
          <span key={t} onClick={()=>setTab(t)} style={{flexShrink:0,padding:"5px 14px",borderRadius:20,fontSize:12,fontWeight:700,cursor:"pointer",
            background:tab===t?T.pri:T.bg,color:tab===t?"#fff":T.t3,border:`1px solid ${tab===t?T.pri:T.bd}`}}>{t}</span>
        ))}
      </div>
      {!q&&<>
        <SectionHdr title="সাম্প্রতিক অনুসন্ধান"/>
        <div style={{display:"flex",gap:8,padding:"0 16px 10px",flexWrap:"wrap"}}>
          {recent.map(r=>(
            <span key={r} onClick={()=>setQ(r)} style={{padding:"6px 12px",borderRadius:20,background:T.bg,border:`1px solid ${T.bd}`,
              fontSize:12,fontWeight:600,color:T.t2,cursor:"pointer"}}>🕐 {r}</span>
          ))}
        </div>
        <SectionHdr title="দ্রুত ফিল্টার"/>
        <div style={{display:"flex",gap:10,padding:"0 16px 10px",overflowX:"auto"}}>
          {[{e:"⏱",l:"চলছে",s:"open"},{e:"📋",l:"আজকের",s:"today"},{e:"❌",l:"পাওয়া যায়নি",s:"notfound"},{e:"⚠️",l:"নেগেটিভ",s:"neg"}].map(f=>(
            <div key={f.l} onClick={()=>setQ(f.l)} style={{flexShrink:0,background:T.bg,border:`0.5px solid ${T.bd}`,borderRadius:14,padding:"10px 14px",
              display:"flex",flexDirection:"column",alignItems:"center",gap:4,cursor:"pointer",minWidth:70}}>
              <span style={{fontSize:20}}>{f.e}</span>
              <span style={{fontSize:11,fontWeight:700,color:T.t2,whiteSpace:"nowrap"}}>{f.l}</span>
            </div>
          ))}
        </div>
      </>}
      {q&&list.map((r,i)=>(
        <div key={i} onClick={()=>go("bazarDetail")} style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,
          margin:"4px 16px",padding:"12px 14px",display:"flex",alignItems:"center",gap:12,cursor:"pointer"}}>
          <div style={{width:36,height:36,borderRadius:12,background:T.bg3,display:"flex",alignItems:"center",justifyContent:"center",fontSize:18}}>{r.icon}</div>
          <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:T.t1}}>{r.title}</div><div style={{fontSize:11,color:T.t3,marginTop:2}}>{r.sub}</div></div>
          <Chip bg={r.chip.bg} color={r.chip.c}>{r.chip.l}</Chip>
        </div>
      ))}
      {q&&list.length===0&&<div style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",padding:"40px 32px",gap:12}}>
        <span style={{fontSize:40}}>🔍</span>
        <div style={{fontSize:14,fontWeight:700,color:T.t1,textAlign:"center"}}>"{q}" — কিছু পাওয়া যায়নি</div>
        <div style={{fontSize:12,color:T.t3,textAlign:"center"}}>অন্য শব্দ দিয়ে চেষ্টা করুন</div>
      </div>}
    </div>
  );
};

// ── SCREEN 17: Settings ────────────────────────────────────────────────────────
const SettingsScreen=({go})=>{
  const [notif,setNotif]=useState(true);const [sound,setSound]=useState(false);const [bangla,setBangla]=useState(true);
  const Toggle=({val,set})=>(
    <div onClick={()=>set(!val)} style={{width:44,height:26,borderRadius:13,background:val?T.pri:T.bg3,transition:"background .2s",cursor:"pointer",position:"relative",flexShrink:0}}>
      <div style={{position:"absolute",top:3,left:val?21:3,width:20,height:20,borderRadius:"50%",background:"#fff",transition:"left .2s",boxShadow:"0 1px 3px rgba(0,0,0,.2)"}}/>
    </div>
  );
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="সেটিংস" onBack={()=>go("more")}/>
      <div style={{height:12}}/>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>নোটিফিকেশন</div>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 12px",overflow:"hidden"}}>
        {[{l:"Push Notification",sub:"বাজার ও টাকার আপডেট",val:notif,set:setNotif},{l:"Sound",sub:"নোটিফিকেশন শব্দ",val:sound,set:setSound}].map((s,i)=>(
          <div key={i} style={{display:"flex",alignItems:"center",gap:12,padding:"13px 14px",borderBottom:i<1?`0.5px solid ${T.bg3}`:"none"}}>
            <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:T.t1}}>{s.l}</div><div style={{fontSize:11,color:T.t3,marginTop:1}}>{s.sub}</div></div>
            <Toggle val={s.val} set={s.set}/>
          </div>
        ))}
      </div>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>ভাষা / Language</div>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 12px",overflow:"hidden"}}>
        {[["বাংলা",true],["English",false]].map(([l,v],i)=>(
          <div key={l} onClick={()=>setBangla(v)} style={{display:"flex",alignItems:"center",gap:12,padding:"13px 14px",borderBottom:i<1?`0.5px solid ${T.bg3}`:"none",cursor:"pointer"}}>
            <div style={{width:20,height:20,borderRadius:"50%",border:`2px solid ${bangla===v?T.pri:T.bd2}`,background:bangla===v?T.pri:"transparent",display:"flex",alignItems:"center",justifyContent:"center"}}>
              {bangla===v&&<div style={{width:8,height:8,borderRadius:"50%",background:"#fff"}}/>}
            </div>
            <span style={{fontSize:13,fontWeight:700,color:T.t1}}>{l}</span>
          </div>
        ))}
      </div>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>ডেটা ও Storage</div>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 12px",overflow:"hidden"}}>
        {[{l:"Local Cache পরিষ্কার করুন",sub:"Offline data মুছে দেবে",color:T.t1},{l:"Sync Queue দেখুন",sub:"Pending items",color:T.pri,action:()=>go("offlineQueue")}].map((item,i)=>(
          <div key={i} onClick={item.action} style={{display:"flex",alignItems:"center",gap:12,padding:"13px 14px",borderBottom:i<1?`0.5px solid ${T.bg3}`:"none",cursor:item.action?"pointer":"default"}}>
            <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:item.color}}>{item.l}</div><div style={{fontSize:11,color:T.t3,marginTop:1}}>{item.sub}</div></div>
            {item.action&&<span style={{fontSize:16,color:T.t4}}>›</span>}
          </div>
        ))}
      </div>
      <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>অ্যাপ তথ্য</div>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 12px",padding:"12px 14px"}}>
        {[["Version","1.0.0 (MVP)"],["Build","2025.05.23"],["Backend","api.bazarkhata.com"]].map(([k,v],i)=>(
          <div key={k} style={{display:"flex",justifyContent:"space-between",marginBottom:i<2?8:0}}>
            <span style={{fontSize:12,color:T.t3,fontWeight:600}}>{k}</span>
            <span style={{fontSize:12,color:T.t1,fontWeight:700}}>{v}</span>
          </div>
        ))}
      </div>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 18: Offline Queue ───────────────────────────────────────────────────
const OfflineQueueScreen=({go,sync})=>{
  const items=[
    {type:"bazar_item",action:"update",entity:"দুধ ২ প্যাকেট — price: ১৩০",time:"৩ মিনিট আগে",retries:0,status:"waiting"},
    {type:"bazar_item",action:"update",entity:"ডিম ৩০টা — status: not_found",time:"৫ মিনিট আগে",retries:0,status:"waiting"},
    {type:"direct_expense",action:"create",entity:"সরাসরি খরচ — ৳ ৫০",time:"৮ মিনিট আগে",retries:1,status:"waiting"},
    {type:"money_entry",action:"create",entity:"টাকা নিলাম — ৳ ৩,০০০",time:"১২ মিনিট আগে",retries:2,status:"failed"},
    {type:"comment",action:"create",entity:"Aarong পাইনি, local নিয়েছি",time:"১৫ মিনিট আগে",retries:0,status:"waiting"},
  ];
  const tIcon={bazar_item:"🛒",direct_expense:"🧾",money_entry:"💵",comment:"💬"};
  const failed=items.filter(i=>i.status==="failed").length;
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="Sync Queue" subtitle="OFFLINE PENDING ITEMS" onBack={()=>go("settings")}/>
      <div style={{background:sync==="offline"?T.ambLt:T.priLt,padding:"10px 16px",display:"flex",alignItems:"center",gap:10}}>
        <span style={{fontSize:18}}>{sync==="offline"?"⚡":"⟳"}</span>
        <div style={{flex:1}}>
          <div style={{fontSize:12,fontWeight:700,color:sync==="offline"?T.ambTx:T.priTx}}>{sync==="offline"?"Offline মোড — Internet নেই":"Sync হচ্ছে…"}</div>
          <div style={{fontSize:11,color:sync==="offline"?T.ambTx:T.priTx,marginTop:1}}>{items.length}টি item পাঠানো বাকি আছে</div>
        </div>
        {failed>0&&<Chip bg={T.redLt} color={T.redTx}>{failed} failed</Chip>}
      </div>
      <div style={{display:"flex",gap:8,padding:"12px 16px 4px"}}>
        <button style={{flex:1,padding:"9px",borderRadius:10,border:`1.5px solid ${T.pri}`,background:T.priLt,color:T.priTx,fontSize:12,fontWeight:700,cursor:"pointer",fontFamily:"inherit"}}>⟳ সব Retry করুন</button>
        <button style={{flex:1,padding:"9px",borderRadius:10,border:`1.5px solid ${T.bd}`,background:T.bg,color:T.t3,fontSize:12,fontWeight:700,cursor:"pointer",fontFamily:"inherit"}}>🗑 Queue মুছুন</button>
      </div>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"10px 16px 10px",overflow:"hidden"}}>
        {items.map((item,i)=>(
          <div key={i} style={{display:"flex",alignItems:"center",gap:11,padding:"11px 14px",borderBottom:i<items.length-1?`0.5px solid ${T.bg3}`:"none"}}>
            <div style={{width:32,height:32,borderRadius:10,background:item.status==="failed"?T.redLt:T.priLt,display:"flex",alignItems:"center",justifyContent:"center",fontSize:15,flexShrink:0}}>{tIcon[item.type]}</div>
            <div style={{flex:1}}>
              <div style={{fontSize:12,fontWeight:700,color:T.t1}}>{item.entity}</div>
              <div style={{fontSize:10,color:T.t3,marginTop:2}}>{item.time} · {item.retries>0?`${item.retries} retry`:item.action}</div>
            </div>
            <Chip bg={item.status==="failed"?T.redLt:T.ambLt} color={item.status==="failed"?T.redTx:T.ambTx} style={{fontSize:10}}>{item.status==="failed"?"failed":"⏳"}</Chip>
          </div>
        ))}
      </div>
      <div style={{margin:"0 16px",padding:"10px 13px",background:T.bg3,borderRadius:12}}>
        <div style={{fontSize:11,color:T.t3,lineHeight:1.5}}>💡 Internet এলে automatically sync হবে। এই page বন্ধ করলেও data নষ্ট হবে না।</div>
      </div>
      <div style={{height:8}}/>
    </div>
  );
};

// ── SCREEN 19: More Hub ────────────────────────────────────────────────────────
const MoreScreen=({go,sync,setSync})=>{
  const menu=[
    {e:"🔔",l:"নোটিফিকেশন",sub:"৩টি নতুন",s:"notifications"},
    {e:"📊",l:"রিপোর্ট",sub:"মে ২০২৫",s:"reports"},
    {e:"👝",l:"ওয়ালেট ডিটেইল",sub:"CEO Personal বিস্তারিত",s:"walletDetail"},
    {e:"📅",l:"হিসাব বন্ধ",sub:"মাসিক closing",s:"monthlyClose"},
    {e:"🔍",l:"খুঁজুন",sub:"বাজার, আইটেম, টাকা",s:"search"},
    {e:"🛡️",l:"Admin Panel",sub:"ইউজার ও ওয়ালেট ম্যানেজ",s:"admin"},
    {e:"⚙️",l:"সেটিংস",sub:"Notification, Language, Data",s:"settings"},
  ];
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:T.bg2,overflowY:"auto"}}>
      <AppBar title="আরো"/>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"12px 16px 10px",padding:"14px"}}>
        <div style={{display:"flex",alignItems:"center",gap:12}}>
          <Avatar label="RU" bg={T.priLt} color={T.priTx} size={48}/>
          <div style={{flex:1}}><div style={{fontSize:15,fontWeight:800,color:T.t1}}>Rahim Uddin</div><div style={{fontSize:12,color:T.t3,marginTop:2}}>01711-XXXXXX</div><Chip bg={T.grnLt} color={T.grnTx} style={{marginTop:5,fontSize:10,padding:"2px 8px"}}>assistant</Chip></div>
          <span style={{fontSize:13,color:T.pri,fontWeight:700,cursor:"pointer"}}>Edit</span>
        </div>
      </div>
      <div style={{background:T.bg,borderRadius:14,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",padding:"12px 14px"}}>
        <div style={{fontSize:11,fontWeight:700,color:T.t3,marginBottom:8,letterSpacing:"0.04em"}}>SYNC STATUS</div>
        <div style={{display:"flex",gap:8}}>
          {[["online",T.grn,"✓ Online"],["syncing",T.pri,"⟳ Syncing"],["offline",T.amb,"⚡ Offline"]].map(([s,c,l])=>(
            <button key={s} onClick={()=>setSync(s)} style={{flex:1,padding:"8px 4px",borderRadius:10,border:`1.5px solid ${sync===s?c:T.bd}`,
              background:sync===s?(s==="online"?T.grnLt:s==="syncing"?T.priLt:T.ambLt):T.bg,
              color:sync===s?c:T.t4,fontSize:11,fontWeight:700,cursor:"pointer",fontFamily:"inherit"}}>{l}</button>
          ))}
        </div>
        {sync==="offline"&&<div style={{marginTop:10,padding:"8px 10px",background:T.ambLt,borderRadius:8,fontSize:11,color:T.ambTx,fontWeight:600}}>⚡ ৫টি item sync queue-এ। <span style={{textDecoration:"underline",cursor:"pointer"}} onClick={()=>go("offlineQueue")}>দেখুন →</span></div>}
      </div>
      <div style={{background:T.bg,borderRadius:16,border:`0.5px solid ${T.bd}`,margin:"0 16px 10px",overflow:"hidden"}}>
        {menu.map((m,i)=>(
          <div key={i} onClick={()=>go(m.s)} style={{display:"flex",alignItems:"center",gap:12,padding:"13px 14px",borderBottom:i<menu.length-1?`0.5px solid ${T.bg3}`:"none",cursor:"pointer"}}>
            <div style={{width:36,height:36,borderRadius:10,background:T.bg3,display:"flex",alignItems:"center",justifyContent:"center",fontSize:18,flexShrink:0}}>{m.e}</div>
            <div style={{flex:1}}><div style={{fontSize:13,fontWeight:700,color:T.t1}}>{m.l}</div><div style={{fontSize:11,color:T.t3,marginTop:1}}>{m.sub}</div></div>
            <span style={{fontSize:16,color:T.t4}}>›</span>
          </div>
        ))}
      </div>
      <GBtn color={T.red} border={T.redLt} onClick={()=>go("login")}>🚪 লগআউট</GBtn>
      <div style={{height:8}}/>
    </div>
  );
};

// ── Item Edit Sheet ────────────────────────────────────────────────────────────
const ItemEditSheet=({item,onSave,onClose})=>{
  const [price,setPrice]=useState(item.price?String(item.price):"");
  const [qty,setQty]=useState(item.qty||"");
  return(
    <div style={{position:"absolute",inset:0,background:"rgba(15,23,42,.5)",display:"flex",flexDirection:"column",justifyContent:"flex-end",zIndex:100}} onClick={onClose}>
      <div onClick={e=>e.stopPropagation()} style={{background:T.bg,borderRadius:"20px 20px 0 0",paddingBottom:20}}>
        <div style={{width:36,height:4,background:T.bd2,borderRadius:2,margin:"10px auto 16px"}}/>
        <div style={{padding:"0 16px 14px",borderBottom:`0.5px solid ${T.bd}`}}>
          <div style={{fontSize:16,fontWeight:800,color:T.t1}}>{item.name}</div>
          <div style={{fontSize:12,color:T.t3,marginTop:3}}>{item.attrs?`${item.qty} · ${item.attrs}`:item.qty}</div>
        </div>
        <div style={{padding:"14px 0 0"}}>
          <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>কতটুকু কিনলেন?</div>
          <input value={qty} onChange={e=>setQty(e.target.value)} placeholder={item.qty}
            style={{margin:"0 16px 12px",width:"calc(100% - 32px)",border:`1.5px solid ${T.bd}`,borderRadius:12,padding:"10px 13px",fontSize:14,color:T.t1,outline:"none",fontFamily:"inherit"}}/>
          <div style={{margin:"0 16px 4px",fontSize:11,fontWeight:700,color:T.t3,letterSpacing:"0.04em"}}>দাম কত হলো? (৳)</div>
          <input value={price} onChange={e=>setPrice(e.target.value)} type="number" placeholder="০"
            style={{margin:"0 16px 12px",width:"calc(100% - 32px)",border:`2px solid ${price?T.grn:T.bd}`,borderRadius:12,padding:"10px 13px",fontSize:24,fontWeight:800,color:T.t1,outline:"none",fontFamily:"inherit"}}/>
          <div style={{display:"flex",gap:8,padding:"0 16px"}}>
            <button onClick={()=>{onSave({...item,price:Number(price),qty,status:"done"});onClose();}} style={{flex:1,background:T.grnSolid,color:"#fff",border:"none",borderRadius:12,padding:"13px",fontSize:13,fontWeight:700,cursor:"pointer",fontFamily:"inherit"}}>✓ কেনা হয়েছে</button>
            <button onClick={()=>{onSave({...item,status:"not_found"});onClose();}} style={{flex:1,background:T.redLt,color:T.redTx,border:`1.5px solid ${T.redLt}`,borderRadius:12,padding:"13px",fontSize:13,fontWeight:700,cursor:"pointer",fontFamily:"inherit"}}>✕ পাওয়া যায়নি</button>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── App Shell ──────────────────────────────────────────────────────────────────
const ALL_SCREENS={
  login:"Login",home:"Home Dashboard",bazarList:"Bazar List",bazarDetail:"Bazar Detail (items + timeline)",
  newBazar:"New Bazar (dual mode)",addItem:"Add Item (manual)",directExpense:"Direct Expense",
  bazarSummary:"Bazar Closed Summary",balance:"Balance / হিসাব",moneyEntry:"Money Entry",
  notifications:"Notifications",reports:"Reports & Charts",walletDetail:"Wallet Detail (owner)",
  monthlyClose:"Monthly Close",admin:"Admin Panel",search:"Search",settings:"Settings",
  offlineQueue:"Offline Sync Queue",more:"More / Profile",
  profileEdit:"Profile Edit",addUser:"Add User (Admin)",bazarComments:"Bazar Comments",
  priceHistory:"Item Price History",assistantLedger:"Assistant Ledger",
};
const NAV_TABS=[{e:"🏠",l:"হোম",s:"home"},{e:"🛒",l:"বাজার",s:"bazarList"},{e:"👝",l:"হিসাব",s:"balance"},{e:"📊",l:"রিপোর্ট",s:"reports"},{e:"⋯",l:"আরো",s:"more"}];
const NO_NAV=["login","newBazar","moneyEntry","addItem","directExpense","search","settings","offlineQueue","monthlyClose","bazarSummary","profileEdit","addUser","bazarComments","priceHistory","assistantLedger"];
const SCREEN_ROWS=[
  ["login","home","bazarList","bazarDetail","newBazar"],
  ["addItem","directExpense","bazarSummary","balance","moneyEntry"],
  ["notifications","reports","walletDetail","monthlyClose","admin"],
  ["search","settings","offlineQueue","more","profileEdit"],
  ["addUser","bazarComments","priceHistory","assistantLedger"],
];

export default function App(){
  const [screen,setScreen]=useState("login");
  const [activeTab,setActiveTab]=useState(0);
  const [itemSheet,setItemSheet]=useState(null);
  const [sync,setSync]=useState("online");
  const go=(s)=>setScreen(s);
  const onItemTap=(item,onSave)=>setItemSheet({item,onSave});
  const SCREENS={
    login:<LoginScreen go={go}/>,
    home:<HomeScreen go={go} sync={sync}/>,
    bazarList:<BazarListScreen go={go}/>,
    bazarDetail:<BazarDetailScreen go={go} onItemTap={onItemTap}/>,
    newBazar:<NewBazarScreen go={go}/>,
    addItem:<AddItemScreen go={go}/>,
    directExpense:<DirectExpenseScreen go={go}/>,
    bazarSummary:<BazarSummaryScreen go={go}/>,
    balance:<BalanceScreen go={go}/>,
    moneyEntry:<MoneyEntryScreen go={go}/>,
    notifications:<NotificationsScreen go={go}/>,
    reports:<ReportsScreen go={go}/>,
    walletDetail:<WalletDetailScreen go={go}/>,
    monthlyClose:<MonthlyCloseScreen go={go}/>,
    admin:<AdminScreen go={go}/>,
    search:<SearchScreen go={go}/>,
    settings:<SettingsScreen go={go}/>,
    offlineQueue:<OfflineQueueScreen go={go} sync={sync}/>,
    more:<MoreScreen go={go} sync={sync} setSync={setSync}/>,
    profileEdit:<ProfileEditScreen go={go}/>,
    addUser:<AddUserScreen go={go}/>,
    bazarComments:<BazarCommentsScreen go={go}/>,
    priceHistory:<PriceHistoryScreen go={go}/>,
    assistantLedger:<AssistantLedgerScreen go={go}/>,
  };
  return(
    <div style={{display:"flex",flexDirection:"column",alignItems:"center",padding:"1rem 0 0",fontFamily:"'Segoe UI',system-ui,sans-serif"}}>
      <div style={{fontSize:11,fontWeight:700,color:"#64748B",letterSpacing:"0.08em",textTransform:"uppercase",marginBottom:6}}>
        {ALL_SCREENS[screen]||screen}
      </div>
      <div style={{width:375,borderRadius:40,border:"8px solid #1a2236",overflow:"hidden",boxShadow:"0 20px 60px rgba(0,0,0,.25)",background:T.bg,display:"flex",flexDirection:"column"}}>
        <div style={{height:40,background:T.pri,display:"flex",alignItems:"center",justifyContent:"space-between",padding:"0 18px",flexShrink:0}}>
          <span style={{color:"#fff",fontSize:12,fontWeight:700}}>9:41</span>
          <div style={{display:"flex",gap:6,color:"#fff",fontSize:12,alignItems:"center"}}>
            {sync==="offline"&&<span style={{fontSize:9,fontWeight:700,background:"rgba(217,119,6,.85)",padding:"1px 6px",borderRadius:10}}>OFFLINE</span>}
            {sync==="syncing"&&<span style={{fontSize:9,fontWeight:700,background:"rgba(21,101,192,.6)",padding:"1px 6px",borderRadius:10}}>⟳</span>}
            <span>WiFi</span><span>🔋</span>
          </div>
        </div>
        <div style={{height:598,overflowY:"auto",overflowX:"hidden",display:"flex",flexDirection:"column",position:"relative",background:T.bg2}}>
          {SCREENS[screen]||SCREENS.home}
          {itemSheet&&<ItemEditSheet item={itemSheet.item} onSave={itemSheet.onSave} onClose={()=>setItemSheet(null)}/>}
        </div>
        {!NO_NAV.includes(screen)&&(
          <div style={{height:72,background:T.bg,borderTop:`0.5px solid ${T.bd}`,display:"flex",alignItems:"center",flexShrink:0}}>
            {NAV_TABS.map((t,i)=>{
              const active=activeTab===i;
              return(<div key={i} onClick={()=>{setActiveTab(i);go(t.s);}} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",gap:2,padding:"8px 0",cursor:"pointer"}}>
                <span style={{fontSize:20}}>{t.e}</span>
                <span style={{fontSize:9,fontWeight:700,color:active?T.pri:T.t4}}>{t.l}</span>
                {active&&<div style={{width:4,height:4,borderRadius:2,background:T.pri,marginTop:1}}/>}
              </div>);
            })}
          </div>
        )}
      </div>
      <div style={{maxWidth:420,marginTop:14,padding:"0 8px"}}>
        {SCREEN_ROWS.map((row,ri)=>(
          <div key={ri} style={{display:"flex",gap:6,flexWrap:"wrap",justifyContent:"center",marginBottom:6}}>
            {row.map(s=>(
              <button key={s} onClick={()=>go(s)} style={{padding:"5px 10px",borderRadius:20,border:"1px solid #E2E8F0",
                background:screen===s?T.pri:"white",color:screen===s?"#fff":"#475569",
                fontSize:11,fontWeight:700,cursor:"pointer",fontFamily:"inherit",whiteSpace:"nowrap"}}>
                {ALL_SCREENS[s].split(/[\s—]/)[0]} {
                s==="bazarDetail"?"Detail":s==="bazarSummary"?"Summary":
                s==="walletDetail"?"Detail":s==="monthlyClose"?"Close":
                s==="offlineQueue"?"Queue":s==="directExpense"?"Expense":
                s==="addItem"?"Add":s==="profileEdit"?"Edit":
                s==="addUser"?"Add":s==="bazarComments"?"Comments":
                s==="priceHistory"?"History":s==="assistantLedger"?"Ledger":""}
              </button>
            ))}
          </div>
        ))}
      </div>
      <div style={{height:12}}/>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADDITIONAL SCREENS (appended)
// ═══════════════════════════════════════════════════════════════════════════════

export const ProfileEditScreen = ({ go }) => {
  const [name, setName] = useState("Rahim Uddin");
  const [phone, setPhone] = useState("01711-XXXXXX");
  const [oldPw, setOldPw] = useState("");
  const [newPw, setNewPw] = useState("");
  const [saved, setSaved] = useState(false);
  return (
    <div style={{ flex:1, display:"flex", flexDirection:"column", background:T.bg2, overflowY:"auto" }}>
      <AppBar title="প্রোফাইল সম্পাদনা" onBack={() => go("more")} />
      <div style={{ alignItems:"center", display:"flex", flexDirection:"column", padding:"20px 0 8px" }}>
        <div style={{ position:"relative" }}>
          <Avatar label="RU" bg={T.priLt} color={T.priTx} size={72} />
          <div style={{ position:"absolute", bottom:0, right:0, width:24, height:24, borderRadius:"50%",
            background:T.pri, display:"flex", alignItems:"center", justifyContent:"center",
            fontSize:13, cursor:"pointer", border:"2px solid #fff" }}>✎</div>
        </div>
        <div style={{ fontSize:11, color:T.pri, fontWeight:700, marginTop:8, cursor:"pointer" }}>ছবি পরিবর্তন করুন</div>
      </div>
      <Divider h={4} />
      <SectionHdr title="ব্যক্তিগত তথ্য" />
      <Field label="পূর্ণ নাম" placeholder="আপনার নাম" value={name} onChange={setName} />
      <Field label="ফোন নম্বর" placeholder="01XXXXXXXXX" value={phone} onChange={setPhone} type="tel" />
      <div style={{ margin:"0 16px 12px", background:T.bg3, borderRadius:12, padding:"11px 14px", display:"flex", gap:8, alignItems:"center" }}>
        <span style={{ fontSize:13, color:T.t3, flex:1 }}>ভূমিকা (Role)</span>
        <Chip bg={T.grnLt} color={T.grnTx}>assistant</Chip>
        <span style={{ fontSize:11, color:T.t4 }}>Admin পরিবর্তন করবেন</span>
      </div>
      <Divider />
      <SectionHdr title="পাসওয়ার্ড পরিবর্তন" />
      <Field label="বর্তমান পাসওয়ার্ড" placeholder="••••••••" value={oldPw} onChange={setOldPw} type="password" />
      <Field label="নতুন পাসওয়ার্ড" placeholder="••••••••" value={newPw} onChange={setNewPw} type="password" />
      {newPw.length > 0 && newPw.length < 8 && (
        <div style={{ margin:"-4px 16px 10px", padding:"8px 12px", background:T.redLt, borderRadius:10, fontSize:11, color:T.redTx, fontWeight:600 }}>
          ⚠️ পাসওয়ার্ড কমপক্ষে ৮ অক্ষর হতে হবে
        </div>
      )}
      {saved && (
        <div style={{ margin:"0 16px 10px", padding:"10px 14px", background:T.grnLt, borderRadius:12, fontSize:12, color:T.grnTx, fontWeight:700 }}>
          ✓ প্রোফাইল সংরক্ষিত হয়েছে
        </div>
      )}
      <PBtn onClick={() => setSaved(true)}>সংরক্ষণ করুন</PBtn>
      <div style={{ height:8 }} />
    </div>
  );
};

export const AddUserScreen = ({ go }) => {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [role, setRole] = useState("assistant");
  const [wallets, setWallets] = useState([]);
  const allWallets = ["Office Wallet", "CEO Personal", "CTO Personal"];
  const toggleWallet = w => setWallets(p => p.includes(w) ? p.filter(x => x !== w) : [...p, w]);
  const roles = [
    { k:"assistant", label:"সহকারী (Assistant)", sub:"সব ওয়ালেট দেখতে পাবে, বাজার করবে", bg:T.grnLt, color:T.grnTx },
    { k:"owner",     label:"মালিক (Owner)",       sub:"নির্দিষ্ট wallet-এর হিসাব ম্যানেজ করবে", bg:T.priLt, color:T.priTx },
    { k:"admin",     label:"অ্যাডমিন (Admin)",    sub:"সম্পূর্ণ সিস্টেম অ্যাক্সেস", bg:T.redLt, color:T.redTx },
  ];
  return (
    <div style={{ flex:1, display:"flex", flexDirection:"column", background:T.bg2, overflowY:"auto" }}>
      <AppBar title="নতুন ইউজার যোগ করুন" subtitle="ADMIN PANEL" onBack={() => go("admin")} />
      <div style={{ height:12 }} />
      <Field label="পূর্ণ নাম *" placeholder="ইউজারের নাম" value={name} onChange={setName}
        style={{ border:`1.5px solid ${name ? T.pri : T.bd}` }} />
      <Field label="ফোন নম্বর *" placeholder="01XXXXXXXXX" value={phone} onChange={setPhone} type="tel"
        style={{ border:`1.5px solid ${phone ? T.pri : T.bd}` }} />
      <div style={{ margin:"0 16px 4px", fontSize:11, fontWeight:700, color:T.t3, letterSpacing:"0.04em" }}>ভূমিকা (Role) *</div>
      <div style={{ margin:"0 16px 12px", display:"flex", flexDirection:"column", gap:8 }}>
        {roles.map(r => (
          <div key={r.k} onClick={() => setRole(r.k)} style={{ display:"flex", alignItems:"center", gap:12,
            padding:"11px 14px", background:role===r.k ? r.bg : T.bg, borderRadius:12,
            border:`1.5px solid ${role===r.k ? r.color : T.bd}`, cursor:"pointer" }}>
            <div style={{ width:20, height:20, borderRadius:"50%", border:`2px solid ${r.color}`,
              background:role===r.k ? r.color : "transparent", display:"flex", alignItems:"center", justifyContent:"center" }}>
              {role===r.k && <div style={{ width:8, height:8, borderRadius:"50%", background:"#fff" }} />}
            </div>
            <div style={{ flex:1 }}>
              <div style={{ fontSize:13, fontWeight:700, color:T.t1 }}>{r.label}</div>
              <div style={{ fontSize:11, color:T.t3 }}>{r.sub}</div>
            </div>
          </div>
        ))}
      </div>
      {role === "owner" && (
        <>
          <div style={{ margin:"0 16px 4px", fontSize:11, fontWeight:700, color:T.t3, letterSpacing:"0.04em" }}>কোন ওয়ালেটের Owner?</div>
          <div style={{ margin:"0 16px 12px", display:"flex", flexDirection:"column", gap:8 }}>
            {allWallets.map(w => (
              <div key={w} onClick={() => toggleWallet(w)} style={{ display:"flex", alignItems:"center", gap:12,
                padding:"11px 14px", background:wallets.includes(w) ? T.priLt : T.bg,
                borderRadius:12, border:`1.5px solid ${wallets.includes(w) ? T.pri : T.bd}`, cursor:"pointer" }}>
                <div style={{ width:20, height:20, borderRadius:6, border:`2px solid ${wallets.includes(w) ? T.pri : T.bd2}`,
                  background:wallets.includes(w) ? T.pri : "transparent", display:"flex", alignItems:"center", justifyContent:"center" }}>
                  {wallets.includes(w) && <span style={{ color:"#fff", fontSize:11, fontWeight:700 }}>✓</span>}
                </div>
                <span style={{ fontSize:13, fontWeight:700, color:T.t1 }}>{w}</span>
              </div>
            ))}
          </div>
        </>
      )}
      <div style={{ margin:"0 16px 12px", padding:"10px 13px", background:T.ambLt, borderRadius:12 }}>
        <div style={{ fontSize:11, fontWeight:700, color:T.ambTx }}>📱 ইউজার প্রথম লগইনে পাসওয়ার্ড সেট করবেন।</div>
      </div>
      <PBtn onClick={() => go("admin")} color={name && phone ? T.pri : T.bd2}>ইউজার তৈরি করুন</PBtn>
      <GBtn onClick={() => go("admin")}>বাতিল করুন</GBtn>
      <div style={{ height:8 }} />
    </div>
  );
};

export const BazarCommentsScreen = ({ go }) => {
  const [text, setText] = useState("");
  const comments = [
    { id:1, user:"CEO", avatar:"CE", time:"১০:৩২ AM", msg:"দুধ Aarong full cream হলে ভালো, না পেলে Milk Vita চলবে।", avatarBg:T.redLt, avatarColor:T.redTx },
    { id:2, user:"Rahim", avatar:"RU", time:"১০:৪৫ AM", msg:"Aarong পাওয়া গেছে। গরুর মাংস নেই, চিকেন নেব?", avatarBg:T.grnLt, avatarColor:T.grnTx },
    { id:3, user:"CEO", avatar:"CE", time:"১০:৫২ AM", msg:"হ্যাঁ, চিকেন ১.৫ কেজি নাও।", avatarBg:T.redLt, avatarColor:T.redTx },
    { id:4, user:"Rahim", avatar:"RU", time:"১১:২০ AM", msg:"✓ চিকেন ১.৫ কেজি নেওয়া হয়েছে — ৳ ৩৬০", avatarBg:T.grnLt, avatarColor:T.grnTx },
  ];
  return (
    <div style={{ flex:1, display:"flex", flexDirection:"column", background:T.bg2 }}>
      <AppBar title="মন্তব্য" subtitle="CEO PERSONAL বাজার" onBack={() => go("bazarDetail")} />
      <div style={{ padding:"8px 16px 4px", background:T.bg, borderBottom:`0.5px solid ${T.bd}`, flexShrink:0 }}>
        <div style={{ fontSize:11, color:T.t3, fontWeight:600 }}>
          💡 মন্তব্য = অডিট নোট। দ্রুত যোগাযোগের জন্য WhatsApp ব্যবহার করুন।
        </div>
      </div>
      <div style={{ flex:1, overflowY:"auto", padding:"12px 16px", display:"flex", flexDirection:"column", gap:12 }}>
        {comments.map(c => (
          <div key={c.id} style={{ display:"flex", gap:10, alignItems:"flex-start" }}>
            <Avatar label={c.avatar} bg={c.avatarBg} color={c.avatarColor} size={32} />
            <div style={{ flex:1 }}>
              <div style={{ display:"flex", alignItems:"baseline", gap:8, marginBottom:4 }}>
                <span style={{ fontSize:12, fontWeight:700, color:T.t1 }}>{c.user}</span>
                <span style={{ fontSize:10, color:T.t4 }}>{c.time}</span>
              </div>
              <div style={{ background:T.bg, borderRadius:"4px 16px 16px 16px", padding:"10px 13px",
                border:`0.5px solid ${T.bd}`, fontSize:13, color:T.t2, lineHeight:1.5 }}>{c.msg}</div>
            </div>
          </div>
        ))}
      </div>
      <div style={{ background:T.bg, borderTop:`0.5px solid ${T.bd}`, padding:"10px 16px 12px", flexShrink:0 }}>
        <div style={{ display:"flex", gap:10, alignItems:"flex-end" }}>
          <Avatar label="RU" bg={T.priLt} color={T.priTx} size={32} />
          <div style={{ flex:1, background:T.bg3, borderRadius:20, padding:"10px 14px", display:"flex", alignItems:"center", gap:8 }}>
            <input value={text} onChange={e=>setText(e.target.value)} placeholder="মন্তব্য লিখুন…"
              style={{ flex:1, background:"transparent", border:"none", outline:"none", fontSize:13, color:T.t1, fontFamily:"inherit" }} />
            <button onClick={() => setText("")} style={{ width:32, height:32, borderRadius:"50%",
              background:text ? T.pri : T.bg3, color:text ? "#fff" : T.t4, border:"none", cursor:text?"pointer":"default",
              fontSize:16, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>↑</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export const PriceHistoryScreen = ({ go }) => {
  const item = { name:"ডিম", unit:"টা" };
  const history = [
    { date:"২৩ মে ২০২৫", qty:"৩০টা", price:210, bazar:"CEO Personal", buyer:"Rahim", perUnit:7.0 },
    { date:"১৫ মে ২০২৫", qty:"৩০টা", price:200, bazar:"Office Lunch",  buyer:"Karim", perUnit:6.67 },
    { date:"৮ মে ২০২৫",  qty:"২০টা", price:130, bazar:"CEO Personal", buyer:"Rahim", perUnit:6.5 },
    { date:"১ মে ২০২৫",  qty:"৩০টা", price:195, bazar:"Office Lunch",  buyer:"Karim", perUnit:6.5 },
    { date:"২২ এপ্রিল",  qty:"৩০টা", price:190, bazar:"CEO Personal", buyer:"Rahim", perUnit:6.33 },
    { date:"১৫ এপ্রিল",  qty:"৩০টা", price:185, bazar:"Office Lunch",  buyer:"Rahim", perUnit:6.17 },
  ];
  const avg = Math.round(history.reduce((s,h) => s + h.perUnit, 0) / history.length * 100) / 100;
  const max = Math.max(...history.map(h => h.price));
  return (
    <div style={{ flex:1, display:"flex", flexDirection:"column", background:T.bg2, overflowY:"auto" }}>
      <AppBar title={`${item.name} — দামের ইতিহাস`} subtitle="ITEM PRICE HISTORY" onBack={() => go("bazarDetail")} />
      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr 1fr", gap:10, padding:"12px 16px 4px" }}>
        {[{ l:"সর্বশেষ দাম", v:`৳ ${history[0].price}`, c:T.t1, bg:T.bg },
          { l:"গড় দাম/টা", v:`৳ ${avg}`, c:T.pri, bg:T.priLt },
          { l:"মোট কেনা", v:`${history.length}বার`, c:T.grn, bg:T.grnLt }].map((s,i) => (
          <div key={i} style={{ background:s.bg, borderRadius:14, padding:"11px 12px", border:`0.5px solid ${T.bd}` }}>
            <div style={{ fontSize:9, fontWeight:700, color:s.c, opacity:.8, letterSpacing:"0.04em", marginBottom:5 }}>{s.l.toUpperCase()}</div>
            <div style={{ fontSize:16, fontWeight:800, color:s.c }}>{s.v}</div>
          </div>
        ))}
      </div>
      <SectionHdr title="দামের প্রবণতা (Chart)" />
      <div style={{ background:T.bg, borderRadius:16, border:`0.5px solid ${T.bd}`, margin:"0 16px 10px", padding:"14px" }}>
        <div style={{ display:"flex", alignItems:"flex-end", gap:6, height:80, marginBottom:8 }}>
          {history.slice().reverse().map((h, i) => (
            <div key={i} style={{ flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:4 }}>
              <div style={{ width:"100%", background:i===history.length-1?T.grn:T.pri, borderRadius:"4px 4px 0 0",
                height:`${(h.price/max)*70}px`, minHeight:4, transition:"height .3s", opacity:i===history.length-1?1:0.6 }} />
              <div style={{ fontSize:8, color:T.t4, fontWeight:600, textAlign:"center", lineHeight:1.2 }}>
                {h.date.split(" ")[0]}<br/>{h.date.split(" ")[1]}
              </div>
            </div>
          ))}
        </div>
        <div style={{ display:"flex", justifyContent:"space-between" }}>
          <span style={{ fontSize:10, color:T.t4 }}>এপ্রিল</span>
          <span style={{ fontSize:10, color:T.grn, fontWeight:700 }}>● আজকে: ৳ {history[0].price}</span>
        </div>
      </div>
      <SectionHdr title="ক্রয়ের বিস্তারিত" />
      <div style={{ background:T.bg, borderRadius:16, border:`0.5px solid ${T.bd}`, margin:"0 16px 10px", overflow:"hidden" }}>
        {history.map((h, i) => (
          <div key={i} style={{ padding:"11px 14px", borderBottom:i<history.length-1?`0.5px solid ${T.bg3}`:"none" }}>
            <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:4 }}>
              <span style={{ fontSize:12, fontWeight:700, color:T.t1 }}>{h.date}</span>
              <span style={{ fontSize:13, fontWeight:800, color:i===0?T.grn:T.t1 }}>৳ {h.price}</span>
            </div>
            <div style={{ display:"flex", gap:12 }}>
              <span style={{ fontSize:11, color:T.t3 }}>{h.qty}</span>
              <span style={{ fontSize:11, color:T.t3 }}>প্রতিটা ৳ {h.perUnit}</span>
              <span style={{ fontSize:11, color:T.t3 }}>{h.bazar}</span>
              <span style={{ fontSize:11, color:T.t4 }}>{h.buyer}</span>
            </div>
          </div>
        ))}
      </div>
      <div style={{ height:8 }} />
    </div>
  );
};

export const AssistantLedgerScreen = ({ go }) => {
  const [assistant, setAssistant] = useState("Rahim");
  const assts = ["Rahim", "Karim"];
  const ledger = [
    { date:"২৩ মে", type:"expense",        wallet:"CEO Personal",  amount:-180,  note:"পাউরুটি কেনা",       running:-180 },
    { date:"২২ মে", type:"money_received",  wallet:"Office Wallet", amount:5000,  note:"মাসের অ্যাডভান্স",  running:4820 },
    { date:"২২ মে", type:"expense",         wallet:"Office Wallet", amount:-3200, note:"Office Lunch বাজার", running:1620 },
    { date:"২১ মে", type:"money_received",  wallet:"CEO Personal",  amount:3000,  note:"CEO gave",           running:4620 },
    { date:"২১ মে", type:"expense",         wallet:"CEO Personal",  amount:-3800, note:"CEO বাজার শেষ",      running:820 },
    { date:"২০ মে", type:"money_returned",  wallet:"Office Wallet", amount:-250,  note:"বাকি ফেরত",          running:1070 },
    { date:"২০ মে", type:"money_received",  wallet:"Office Wallet", amount:5000,  note:"অ্যাডভান্স",        running:1320 },
  ];
  const tC = {
    money_received:{ color:T.grn, bg:T.grnLt, icon:"💵", sign:"+" },
    expense:       { color:T.red, bg:T.redLt, icon:"🛒", sign:"-" },
    money_returned:{ color:T.amb, bg:T.ambLt, icon:"↩️", sign:"-" },
  };
  const totalHeld = ledger[0].running;
  return (
    <div style={{ flex:1, display:"flex", flexDirection:"column", background:T.bg2, overflowY:"auto" }}>
      <AppBar title="সহকারী লেজার" subtitle="ASSISTANT LEDGER" onBack={() => go("balance")} />
      <div style={{ display:"flex", gap:8, padding:"12px 16px 4px" }}>
        {assts.map(a => (
          <span key={a} onClick={() => setAssistant(a)} style={{ padding:"6px 14px", borderRadius:20, fontSize:13,
            fontWeight:700, cursor:"pointer", background:assistant===a ? T.pri : T.bg,
            color:assistant===a ? "#fff" : T.t3, border:`1px solid ${assistant===a ? T.pri : T.bd}` }}>{a}</span>
        ))}
      </div>
      <div style={{ background:totalHeld>=0?T.grnSolid:T.redSolid, margin:"12px 16px", borderRadius:18, padding:"16px" }}>
        <div style={{ color:"rgba(255,255,255,.75)", fontSize:11, fontWeight:700, letterSpacing:"0.06em", marginBottom:6 }}>
          {assistant} — সর্বমোট হাতে আছে
        </div>
        <div style={{ color:"#fff", fontSize:28, fontWeight:900, letterSpacing:"-0.5px" }}>
          ৳ {Math.abs(totalHeld).toLocaleString()}
        </div>
        <div style={{ color:"rgba(255,255,255,.75)", fontSize:11, fontWeight:600, marginTop:4 }}>
          {totalHeld>=0 ? "সব ওয়ালেট মিলিয়ে হাতে আছে" : "সব ওয়ালেট মিলিয়ে পাওনা আছে"}
        </div>
        <div style={{ height:"0.5px", background:"rgba(255,255,255,.2)", margin:"12px 0" }} />
        <div style={{ display:"flex", gap:16 }}>
          {[["Office Wallet", "৳ ৮০০"], ["CEO Personal", "-৳ ১,২০০"], ["CTO Personal", "৳ ০"]].map(([w,b],i) => (
            <div key={i}>
              <div style={{ fontSize:9, color:"rgba(255,255,255,.65)", fontWeight:700, letterSpacing:"0.05em" }}>{w.split(" ")[0].toUpperCase()}</div>
              <div style={{ fontSize:12, color:"#fff", fontWeight:700, marginTop:2 }}>{b}</div>
            </div>
          ))}
        </div>
      </div>
      <SectionHdr title="সম্পূর্ণ লেনদেন লেজার" />
      <div style={{ background:T.bg, borderRadius:16, border:`0.5px solid ${T.bd}`, margin:"0 16px 10px", overflow:"hidden" }}>
        <div style={{ display:"grid", gridTemplateColumns:"1.5fr 2fr 1fr 1fr", padding:"8px 12px", background:T.bg3 }}>
          {["তারিখ","বিবরণ","পরিমাণ","ব্যালেন্স"].map(h => (
            <div key={h} style={{ fontSize:9, fontWeight:700, color:T.t3, letterSpacing:"0.04em" }}>{h}</div>
          ))}
        </div>
        {ledger.map((e, i) => {
          const c = tC[e.type];
          return (
            <div key={i} style={{ display:"grid", gridTemplateColumns:"1.5fr 2fr 1fr 1fr", padding:"10px 12px",
              borderTop:`0.5px solid ${T.bg3}`, alignItems:"center" }}>
              <div style={{ fontSize:11, color:T.t3 }}>{e.date}</div>
              <div>
                <div style={{ fontSize:11, fontWeight:700, color:T.t1, lineHeight:1.3 }}>{e.note}</div>
                <div style={{ fontSize:9, color:T.t4, marginTop:1 }}>{e.wallet.split(" ")[0]}</div>
              </div>
              <div style={{ fontSize:11, fontWeight:800, color:c.color }}>{c.sign}৳{Math.abs(e.amount).toLocaleString()}</div>
              <div style={{ fontSize:11, fontWeight:700, color:e.running>=0?T.grn:T.red }}>৳{Math.abs(e.running).toLocaleString()}</div>
            </div>
          );
        })}
      </div>
      <div style={{ height:8 }} />
    </div>
  );
};
