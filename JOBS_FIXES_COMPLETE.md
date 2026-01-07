d
if needeng PHP API tiith exispatible womard ce backwares angl chxt)
- AlD" te"No TMIothing (no s show n TMIDty"
- Empersportnknown Tran"U names show ransporterg ty or missinion)
- Emptinal positay in origsts  (jobcefully handled grarrors areing e- Date parsring
 filteafterent-side s done cli
- Sorting i## Notes
rder

est-first ontain new maill filters**: Aingrtt Soten **Consisy
5.s quicklPI issueentify A idlogs helpg *: Debung*uggi Deb4. **Betterays show
MID alw Tme andks ensure na fallbaciple*: Multy*splable DiReliaon
3. **cting see pendi thteringcluts ired jobxp: No eding View***Cleaner Penies
2. *portunit fresh opndasier to fi it eaking first, mest jobsew Users see ner UX**:Bett

1. **ts
## Benefi}
```
"..."
d": rter_tmitranspo",
  " "...terTmid":nspor,
  "trae": "..."rterNam "transpo
 ``json
{k)
`(Fallbacats rmrnative Fo

### Alte
```"
}0:13:0509-03 05-": "202ated_at"Cre0",
   "TMJB0026ob_id":
  "j05562",M2509ARTRd": "T_unique_iter  "transpori",
hit swam: "Roer_name"ansport "trn
{
 ``jso)
`at (PrimaryFormaravel API ## Lrmats:

#response foI tiple AP handles mulow
The code nndling
Response Ha

## API  datangsilues for mis default va- Addedd TMID
   rter name an transpoling forer handbettdded  As
   -lbackeld name falfie multipl()` with elJsonLarav`fromEnhanced rt**
   - dab_model./jodelsb/mo2. **li

esPI responsing for Adebug logg Added  jobs
   -xpiredto exclude eg filter ted pendin
   - Updar filteringafteg logic ind sort   - Addeart**
ervice.dapi_s2_ces/phasee/servilib/cor
1. ** Modified
 Filesrectly

## display corbadgesb card ts
- [x] Joresulwith sorted ality works ctionch fun [x] Searorrectly
-rs work cilte All other f
- [x]bsired jonly expows oed filter shx] Expirjobs
- [red xcludes expir efilteding 
- [x] Pene topnewest at thed with re sort] Jobs acards
- [xtly in job correcme displays orter naansp
- [x] Tr job cardscorrectly insplays x] TMID di- [
 Checklist

## Testing
```
ruck drivertle: Heavy tjob_ti  TMJB00260
 _id: 
   jobRTR05562509A TM2que_id:_unitransporter
   mit swaname: Rohiansporter_trb data:
    jo📋 Sampleravel API
Laobs from 5 jFetched 2✅ :

```
hoot issuesroubles t to helpatab dple jo logs sam now serviceThe APIdded

gging A Lobug## De first |

storted newe_job=1), s (closed jobsosedly cl | Onlosed**| **C first |
ewest n, sortedd)dline passed jobs (dealy expireed** | On**Expir |
| est first new sortedve=0),e_inactiactivs (active jobOnly in** | *Inactiverst |
| *newest fiorted ed, sre NOT expir atus=0) thatg jobs (sta pendin| OnlyPending** irst |
| **newest f, sorted piredT ext are NOe=1) thativac(active_inve jobs  | Only acti| **Active**st |
est fir sorted newtus=1),d jobs (staly approveved** | On
| **Approirst | fd newest sorte),g expiredludin (incbsl** | All jo-|
| **Al----|------
|----| Shows | Filter Fixes

|fter  Aaviorr Beh

## Filtereak;
```t();
  b).toLisneiredByDeadlisExp && !job.ioved !job.isAppr(job) =>lJobs.where(Jobs = aledilterection
  fom pending sobs fred j expir // Excludending':
 
case 'pe**:
```dartanges**Code Chonable

and actiean ction clpending se
- Keeps ers"All" filtnd " aedExpirear in "nly appobs now oed jobs
- Expirred jxclude expiogic to eng filter lted pendi**:
- Updaion

**Solutfusioning confilter, caus"Pending"  g in theshowinobs were ed jxpiroblem**: E
**PrtionPending SecJobs in red  ✅ No Expi``

### 3.});
`rn 0;
  }
  retuh (e) {
    } catct first
// NewesteA); (dapareTodateB.comreturn   ;
  edAt)creat(b.Time.parse= Datefinal dateB dAt);
    rse(a.createime.paateA = DateT    final d{
  try {
b) ((a, rtJobs.sofilteredtop
 at the s (newest): Fresh jobjobsrt Soart
// s**:
```dngehae C

**Codrformancetain peing to mainfilterafter happens g tinws
- Sorer viell filtrst in ar fipeaaps now  Newest jober
-rdscending on de_at` date i`Createding by  sorted:
- Addn**tioluings

**Sostwest pond ne hard to fimaking ited,  sort were notbsroblem**: Jo**PTop
 at the bs. ✅ Fresh Jo

### 2  '';
```              
       String() ?? d']?.to_tmitransporter['        json          
      ring() ??id']?.toStporterTmjson['trans                       ) ?? 
ng(Strid']?.tonique_iter_u'transpor = json[nsporterTmid
final transporter';
own Tra  'Unkn                
      ring() ??.toStrterName']?son['transpo    j            
        ring() ??ame']?.toStransporter_nn['tName = jso transporterfinalacks
allb fID withme and TM nasporterranract t
// Ext:
```dartnges***Code Chare

*tuse strucspontrack API reg to ind debug loggsing
- Adde mis name isr" if Transporte"Unknownault value ed def`
- Addmider_torttranspd` or `nsporterTmi_id` or `traniqueransporter_ue`
  - `torterNamransp or `tname`transporter_s:
  - `ponse formatesent API ror differsupport fes
- Added ld namback fiellle faith multip method wryfactoelJson()` Laravanced `fromnh
- Eution**: 

**Soljob cards in howingre not sand TMID weporter name **: Transblemro*P
*eiblNot Visand Name . ✅ TMID 
### 1ed
Fixs ## Issuee

letn Fixes Compbs Scree# Jo