	-----------------------------------------------------------------------------------------------start change render engine part 1
	if (( JustSPeeding != undefined) and ( JustSPeeding.isdisplayed)) do
(destroyDialog JustSPeeding_rollout ) -- test if dialog exist

fn checkRender nSearch = -- function check if render installed
(
theRenderer = for obj in RendererClass.classes where \
(matchPattern (obj as string) pattern:nSearch) -- check if the name in nSearch variable exist
collect obj
if theRenderer.count ==1
then renderers.current = theRenderer[1]()
else
(messageBox "render not installed")


)

	------------------------------------------------------------------------------------------------end change render engine part 1

macroScript TM2ManiaPark

category:"ManiaPark"

tooltip:"TM2 Script"

buttontext:"TM2"



(
 rollout ManiaPark "ManiaPlanet Tool"

 (
	 

	button UVW "Unwrap UVW" toolTip:"Open Uvw Editor" pos:[2,5] 
	spinner sp1 "Copy from"  range:[1,99,1] type:#integer scale:1 fieldwidth:28  align:#left
	spinner sp2 "Copy To   " range:[1,99,2]  type:#integer scale:1 fieldwidth:28 align:#right offset:[-40,-22]
	checkbox ignoreChannelInfo_osd "don't use Channel Info" checked:false pos:[2,50]
	checkbox usePrevUVW_osd "use previous unwrap" checked:false pos:[130,50]
	button CopyUVWChannel "Copy UVW channels" tooltip:"Copy UVW from chanel x to chanel x" pos:[2,70]
	button openchannelinfo "Open Channel Info" pos:[120,70] toolTip:"Open Chanel Editor for renaming map:1 to Material and map:2 to Lightmap "
	button S10 "Scale uvw 1/2" toolTip:"Scale the selected faces by 1/2 in uvw space" pos:[2,95]
	button Relaxuvw "relax uvw" tooltip:"Relax UVW Selection" pos:[90,95]
	button Iron "Iron" tooltip:"Relax UVW Selection to 1 shell" pos:[160,95]
	button stitch "stitch" tooltip:"Stitch the UVW"pos:[200,95]
	Label lbl "<<Select Vertex For PivotPosistion>>" pos:[2,125] 
	button Change "CHANGE" pos:[185,120] toolTip:"Select a vertex in polymode where you want to place the pivot from that object on"
	button ProjShad "ProjShad" pos:[2,145]  toolTip:"Create your ProjShad plane and correct pivot" 
	button MaxBox "Maxbox" pos:[65,145] toolTip:"Create maxbox to see if your model is fitting in it"
	button lights "Car Lights" pos:[95,170]toolTip:"create your carLight with correct pivot" 
	button LightFProj "Light  ProjShad" pos:[2,170] toolTip:"Create your LightProjShad plane and correct pivot"
	button butScanline "Scanline" pos:[2,195] 
	button butMR "Mental Ray"  pos:[60,195] 
	button butVray "Vray"  pos:[135,195] 
	button butFree "iray" pos:[180,195]
	progressBar pBar value:0 color:blue 
	label lbl1 "Script Made by JustSpeeding" pos:[2,235] 
	label lbl2 "Free use For TM Carpark/ManiPark Modelers" pos:[2,250] 
	
	 ------------------------------------------------------------------------------



------------------------------------------------------------------start open uvw
  	on UVW pressed do
	(
		macros.run "Modifiers" "Unwrap_UVW"
	)
--------------------------------------------------------end open uvw
-------------------------------------------------------- start open Channel info
on openchannelinfo pressed do 
	(--UV Channel Listener
			ChannelInfo.dialog();

	)
	
--------------------------------------------------------end open channel info
	-----------------------------------------------------start copy map channel
fn isGeometry obj = ( if ( isKindOf obj geometryClass and classof obj != TargetObject ) then true else false )

fn filterGeometry sel = (for obj in sel where isGeometry obj collect obj)

fn setUnwrapContext obj objUnwrapMod =
	(
	if modPanel.getCurrentObject()==undefined do max modify mode
	if selection.count!=1 do select obj
	if selection[1]!=obj do select obj
	if modPanel.getCurrentObject()!=objUnwrapMod do modPanel.setCurrentObject objUnwrapMod
	)

fn isEditable obj =
	(
	local classOfObj=classOf obj
	case classOfObj of
		(
		Editable_Poly: true
		PolyMeshObject: true
		Editable_mesh: true
		default: false
		)
	)

fn getThisOp obj =
	(
	local classOfObj=classOf obj
	local thisOp
	case classOfObj of
		(
		Editable_Poly: thisOp=polyOp
		PolyMeshObject: thisOp=polyOp
		Editable_mesh: thisOp=meshOp
		default: ( addModifier obj (Edit_Mesh ()) ; thisOp=meshOp )
		)
	thisOp
	)

fn copyMapChannel objUnwrapMod fromChannel toChannel =
	(
	local objUnwrap1=objUnwrapMod.unwrap
	local objUnwrap2=objUnwrapMod.unwrap2
	local thisElementMode=objUnwrap2.getTVElementMode()
	local thisSubObjectMode=objUnwrap2.getTVSubObjectMode()
	objUnwrap2.setTVElementMode false
	objUnwrap2.setTVSubObjectMode 3
	local thisFaces=objUnwrap2.getSelectedFaces()
	objUnwrap1.setMapChannel fromChannel
	modPanel.setCurrentObject objUnwrapMod -- update
	local theFaces=#{1..objUnwrap1.numberPolygons()}
	objUnwrap2.selectFaces theFaces
	objUnwrap2.copy()
	objUnwrap1.setMapChannel toChannel
	modPanel.setCurrentObject objUnwrapMod -- update
	objUnwrap2.selectFaces theFaces
	objUnwrap2.paste false
	objUnwrap2.selectFaces thisFaces
	objUnwrap2.setTVElementMode thisElementMode
	objUnwrap2.setTVSubObjectMode thisSubObjectMode
	)

fn copyMapChannel2 obj fromChannel toChannel =
	(
	local thisOp=getThisOp obj
	local currentNumMaps=(thisOp.getNumMaps obj)-1
	if currentNumMaps<1 do thisOp.setNumMaps obj toChannel+1 keep:true
	local currentMapSupport1=thisOp.getMapSupport obj fromChannel
	if currentMapSupport1==false do thisOp.defaultMapFaces obj fromChannel
	local currentMapSupport2=thisOp.getMapSupport obj toChannel
	if currentMapSupport2==false do thisOp.defaultMapFaces obj toChannel
	channelInfo.CopyChannel obj 3 fromChannel
	channelInfo.PasteChannel obj 3 toChannel
	)

fn addUnwrapIfNecessary obj channel reuse =
	(
	if ( reuse and (classof obj.modifiers[1]==Unwrap_UVW) )
		then (
			currentChannel=obj.modifiers[1].unwrap.getMapChannel()
			case currentChannel of
				(
				0: currentChannel=1
				1: currentChannel=0
				)
			if channel==currentChannel
				then obj.modifiers[1]
				else (
					objUnwrapMod=Unwrap_UVW()
					addModifier obj objUnwrapMod
					objUnwrapMod.unwrap.setMapChannel channel
					objUnwrapMod
					)
			)
		else (
			objUnwrapMod=Unwrap_UVW()
			addModifier obj objUnwrapMod
			objUnwrapMod.unwrap.setMapChannel channel
			objUnwrapMod
			)
		)--fn

on copyMapChannelRollout open do
(
	local vn=maxVersion()
	if vn[1]<6000 do ( ignoreChannelInfo_osd.checked=true ; ignoreChannelInfo_osd.enabled=false )
)

on CopyUVWChannel pressed do
(
	sel=selection as array
	sel=filterGeometry sel
	if sel.count>0
		then (
			local vn=maxVersion()
			startTime=timeStamp()
			undo off (
				for i=1 to sel.count do (
					obj=sel[i]
					select obj
					local newMode=false
					if vn[1]>=6000 do newMode=true
					if ignoreChannelInfo_osd.checked do newMode=false
					if not isEditable obj do newMode=false
					if newMode do ( copyMapChannel2 obj sp1.value sp2.value )
					objUnwrapMod=addUnwrapIfNecessary obj sp2.value usePrevUVW_osd.checked
					objUnwrapMod.name="Unwrap UVW ch"+(sp2.value as string)
					setUnwrapContext obj objUnwrapMod
					if not newMode do ( copyMapChannel objUnwrapMod sp1.value sp2.value )
					pBar.value=((i as float/sel.count as float)*100.0)as integer
					)
				)--undo off
			endTime=timeStamp()
			format "copyMapChannel: Processing took % seconds\n" ((endTime-startTime) / 1000.0)
			pBar.value=0
			select sel
			max views redraw
			)
		else messageBox("select at least one object")
)--on

	
	
	-----------------------------------------------------end copy map channel
--------------------------------------------------------start Scale50% uvw
on S10 pressed do
	(
		selectionSets["tempSel"] = selection
		
		sel = selection
	
		obj = #()
	
		for i in sel do
		(
		append obj i
		)
	
		for i = 1 to obj.count do
		(
		select obj[i]
	
		obj[i].modifiers[#unwrap_uvw].unwrap.edit ()
	
		obj[i].modifiers[#unwrap_uvw].setTVSubObjectMode 3
	
		face = obj[i].modifiers[#unwrap_uvw].getSelectedFaces
	
		obj[i].modifiers[#unwrap_uvw].unwrap2.ScaleSelectedCenter 0.5 0
	
		clearSelection()
			
		select selectionSets["tempSel"]
		
		for i in sel do
		(
			i.modifiers[#unwrap_uvw].unwrap.edit ()
			i.modifiers[#unwrap_uvw].setTVSubObjectMode 3
		)
		
		)
	)
	

--------------------------------------------------------end Scale50% uvw
--------------------------------------------------------start relex uvw
	on Relaxuvw pressed do
		(
	if classof (modPanel.getCurrentObject()) == Unwrap_UVW then(
		undo on(
			local uv = modPanel.getCurrentObject();
			
			local gRi = uv.unwrap3.getRelaxIteration();
			local gRa = uv.unwrap3.getRelaxAmount();
			
			case uv.gettvsubobjectmode() of(
				1: (
					uv.unwrap3.setRelaxIteration 200;--deafult 100
					uv.unwrap3.setRelaxAmount 1;--default 0.1
					uv.unwrap3.relax2();
				)
				2: (
					--edge selection
					uv.relaxByEdgeAngle 1000 0 1 false;
				)
				3: (
					
					uv.unwrap5.relaxByFaceAngle 1000 0 1 false;
				)
			)
			
			--restore previous settings
			uv.unwrap3.setRelaxIteration gRi;
			uv.unwrap3.setRelaxAmount gRa;
		)
	)
)
--------------------------------------------------------end relex uvw
--------------------------------------------------------Start iron uvw
on Iron pressed do
	(

		
	
	function flattenSelForNode obj uv=(
		local numFacesSelected;-- = ( uv.unwrap.getSelectedPolygons() ).numberSet;
		if ((maxVersion())[1] >= 10000 )then(--max2008+ version
			numFacesSelected = (uv.unwrap6.getSelectedFacesByNode obj).numberSet;
		)else(
			numFacesSelected = ( uv.unwrap.getSelectedPolygons() ).numberSet;
		)
		
		--print("facenum "+numFacesSelected as string);
		if (numFacesSelected > 0)then(
			local var_a = uv.unwrap3.getRelaxIteration();
			
			uv.unwrap5.quickPlanarMap();--quick flatten
			uv.unwrap3.setRelaxIteration 1000;
			uv.unwrap3.relax2();
			
			---restore previous settings
			uv.unwrap3.setRelaxIteration var_a;
		)
	)
	
	
	
		
	if (selection.count > 0)then(--at least an object selected
		local uv = modPanel.getCurrentObject();
		if( classof(uv) == Unwrap_UVW)then(
			undo on(
				if ((maxVersion())[1] >= 10000 )then(
					for sel in selection do(
						flattenSelForNode sel uv;
					)
				)else(
					flattenSelForNode selection[1] uv;--only do this with the first object in the selection
				)
			)
		)
	)	
				
)




--------------------------------------------------------end Iron uvw
--------------------------------------------------------Start stitch uvw
on stitch pressed do
	(
	clearListener();
	undo on(
		if (selection.count > 0)then(--at least an object selected
			local obj = selection[1]; 
			--if (classOf obj.baseObject == Editable_Poly) then (--only if this 1st object is a poly at its base
			if (superclassof obj == GeometryClass)then(
				
				if (obj.modifiers[ #unwrap_uvw ] != undefined) then(
					local uv = obj.modifiers[ #unwrap_uvw ];
					if (selectOnly== true)then(
						case uv.gettvsubobjectmode() of(--convert selection
							1: (
								uv.verttoedgeselect()
							)
							3: (
								uv.facetoedgeselect()
							)
						)
						sel_org = uv.getselectededges();
						sel = (uv.getselectededges()) as array;
						if sel.count > 0 do(
							--isolate to just border edges
							local found = false;
							for e=1 to sel.count do(
								uv.unwrap2.selectEdges #{sel[e]};
								uv.unwrap2.openEdgeSelect();
								
								local edges_sel = (uv.getselectededges()).numberset;
								if (edges_sel > 1)then(
									print("done: !!\t"+edges_sel as string+".."+(uv.getselectededges()) as string);
									--uv.unwrap2.selectEdges ((uv.getselectededges()) - #{sel[e]});
									found = true;
									exit;
								)
							)
							if (found == true)then(
								print("yes I can continue...");
								
								--uv.unwrap2.selectEdges #{1.. uv.}
								sel_border = uv.getselectededges();
									
								--select all
								uv.selectFaces #{1.. uv.numberPolygons()};
								uv.facetoedgeselect();
								sel_all =  uv.getselectededges();
									
								uv.unwrap2.selectEdges (sel_org-(sel_all-sel_border));--now contract all edges that are not part of the border
								
								uv.unwrap2.setTVSubObjectMode 2;
								uv.selectFaces #{};
							)
						)
					)else(
						uv.unwrap2.stitchVertsNoParams();
					)
				)else(
					print("no UV editor present...");
				)
			)
		)
	)
)

--------------------------------------------------------end  stitch uvw
--------------------------------------------------------start Change pivot
on change pressed do
	(
		if subobjectLevel == 0 then
		(
		messageBox "Please select the vertex and then hit CHANGE"
		)else
		(
		NoOfObj = getCurrentSelection()
		for i = 1 to NoOfObj.count do
			(
			SelVert = NoOfObj[i].selectedVerts
			SelVertBitArr = SelVert as BitArray
			SelVertArr = SelVertBitArr as array
			VertPos = polyOp.getVert NoOfObj[i] SelVertArr[1]
			NoOfObj[i].pivot = VertPos
			)
		subobjectLevel = 0
		)
	)
--------------------------------------------------------end  Change pivot
------------------------------------------------------------------------------------------------start projshad	
		on ProjShad pressed do
	
if $projshad != undefined 
then
(messageBox "ProjShad already created!")

else
	(p = Plane lengthsegs:1 widthsegs:1 Pos:[0,0,-0.03] Length:6 Width:4 wirecolor:white name:"ProjShad"
    fn DumpXForms obj =

( -- output node transform properties
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
-- output node's pivot point location
format "%:\t%\n" "pivot " obj.pivot
-- output object offsets
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
-- output object transform
format "%:\t%\n" "objecttransform " obj.objecttransform
-- output vertex position in local and world coordinates
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
-- calculate and output vertex position in world coordinates
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)

-- define function for rotating only the pivot point 
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)


	p.pivot=[0,0,0]
	RotatePivotOnly p (Eulerangles 90 0 0)
	
	)
	------------------------------------------------------------------------------------------------end projshad
	------------------------------------------------------------------------------------------------start maxbox
	on MaxBox pressed do
	if $MaxBox != undefined 

 then

(messageBox "MaxBox already created!")
else
	(Box lengthsegs:1 widthsegs:1 heightsegs:1 length:6 width:3 height:2.7 pos:[0,0,-0.2] wirecolor:red name:"MaxBox" 
	)
	------------------------------------------------------------------------------------------------end maxbox
	------------------------------------------------------------------------------------------------start Lightprojshad
		on LightFProj pressed do

if $LightFProj != undefined 
then
(messageBox "LightFProj already created!")
else

(lp = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[0,-2.2,0.58] wirecolor:yellow name:"LightFProj"
		rot_lp = eulerangles 90 0 0
	rotate lp rot_lp 
		fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly lp (Eulerangles -90 0 0)
)
	------------------------------------------------------------------------------------------------end Lightprojshad
	------------------------------------------------------------------------------------------------start Lights
		on lights pressed do
	
	if $LightRR != undefined 
then
(messageBox "Lights already created!")
else
	
	(rr = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[-0.7,2.14,0.8] wirecolor:yellow name:"LightRR"
	rot_rr = eulerangles -90 0 0
	rotate rr rot_rr 
		fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly rr (Eulerangles -90 0 0)
	
	rl = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[0.7,2.14,0.8] wirecolor:yellow name:"LightRL"
	rot_rl = eulerangles -90 0 0
	rotate rl rot_rl 
	fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly rl (Eulerangles -90 0 0)
	
	fr1 = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[-0.78,-1.95,0.58] wirecolor:yellow name:"LightFR1"
	
rot_fr1 = eulerangles 90 0 0
	rotate fr1 rot_fr1 
	fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly fr1 (Eulerangles -90 0 0)	
		
	fr2 = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[-0.68,-1.95,0.516] wirecolor:yellow name:"LightFR2"
rot_fr2 = eulerangles 90 0 0
	rotate fr2 rot_fr2 
	fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly fr2 (Eulerangles -90 0 0)	

    fr3 = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[-0.57,-1.95,0.452] wirecolor:yellow name:"LightFR3"
rot_fr3 = eulerangles 90 0 0
	rotate fr3 rot_fr3 
	fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly fr3 (Eulerangles -90 0 0)	

	fl1 = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[0.78,-1.95,0.58] wirecolor:yellow name:"LightFL1"
	
	rot_fl1 = eulerangles 90 0 0
	rotate fl1 rot_fl1 
	fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly fl1 (Eulerangles -90 0 0)	

	
	fl2 = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[0.68,-1.95,0.516] wirecolor:yellow name:"LightFL2"

	rot_fl2 = eulerangles 90 0 0
	rotate fl2 rot_fl2 
	fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly fl2 (Eulerangles -90 0 0)

    fl3 = Plane lengthsegs:1 widthsegs:1 length:0.1 width:0.1 pos:[0.57,-1.95,0.452] wirecolor:yellow name:"LightFL3"
	
	rot_fl3 = eulerangles 90 0 0
	rotate fl3 rot_fl3 
	fn DumpXForms obj =

(
format "%:\t%\n" "transform" obj.transform
format "%:\t%\n" "position " obj.pos
format "%:\t%\n" "rotation " obj.rotation
format "%:\t%\n" "pivot " obj.pivot
format "%:\t%\n" "objectoffsetpos " obj.objectoffsetpos
format "%:\t%\n" "objectoffsetrot " obj.objectoffsetrot
format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
format "%:\t%\n" "objecttransform " obj.objecttransform
format "%:\t%\n" "vert 1 (local) " (in coordsys local getvert obj 1)
format "%:\t%\n" "vert 1 (world1) " (in coordsys world getvert obj 1)
local v_pos=(in coordsys local getvert obj 1)* obj.objecttransform
format "%:\t%\n" "vert 1 (world2) " v_pos
)
fn RotatePivotOnly obj rotation= ( local rotValInv=inverse (rotation as quat)
animate off in coordsys local obj.rotation*=RotValInv
obj.objectoffsetrot*=RotValInv
obj.objectoffsetpos*=RotValInv
)

	RotatePivotOnly fl3 (Eulerangles -90 0 0)
	
)
	------------------------------------------------------------------------------------------------end Lights

	
		------------------------------------------------------------------------------------------------start change render engine part 2
	on butScanline pressed do
(
varScan = "*Scanline*"
checkRender varScan
)

on butMR pressed do
(
varMR = "*mental_ray*"
checkRender varMR
)

on butVray pressed do
(
varVray = "V_Ray_Adv*"
checkRender varVray

)

on butFree pressed do
(
varIR = "*iray*"
checkRender varIR
)

	------------------------------------------------------------------------------------------------endchange render engine part 2
)
 --end rollout

createDialog ManiaPark 250 270---

)
