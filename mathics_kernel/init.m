(* ::Package:: *)
Print["Loading the package"];

BeginPackage["Jupyter`"];
(* Process the output *)
Jupyter`tmpdir = CreateDirectory[];
imagewidth = 300;

SetImageWidth[width_]:=(imagewidth=width);


SetImageOutputFormat::usage="Set the type of image output to format. Accepts  strings \"svg\" or \"png\" ";

ImageOutputFormat::usage="Returns the current image output format";

InteractiveGraphics3D::usage="Activate or deactivate the Three.js graphics3d support";


ImageWidth[]:=imagewidth;
$DisplayFunction=Identity;


(*Internals: Hacks Print and Message to have the proper format*)

Begin["Jupyter`Private`"];
InteractiveGraphics3D[]:=If[JupyterReturn3D==JupyterReturn3DThree, "On", "Off"];
InteractiveGraphics3D["On"]:=(JupyterReturn3D=JupyterReturn3DThree);
InteractiveGraphics3D["Off"]:=(JupyterReturn3D=JupyterReturn3DImage);


SetImageOutputFormat[format_]:=(If[format=="svg",JupyterReturnImage = JupyterReturnBase64SVG,
                                                If[format=="jpg",JupyterReturnImage = JupyterReturnBase64JPG,
                                                If[format=="png", JupyterReturnImage = JupyterReturnBase64PNG,
                                                Print["`format` should be one of \"svg\", \"png\" or \"jpg\" "]]]];
				If[JupyterReturn3D==JupyterReturn3DImage,InteractiveGraphics3D["Off"]];)

ImageOutputFormat[]:=If[JupyterReturnImage == JupyterReturnBase64SVG,"svg",If[JupyterReturnImage==JupyterReturnBase64JPG,"jpg","png"]];
If[StringTake[$Version,{1,7}] == "Mathics", Mathics=True; Print["Running Mathics"]; , Mathics=False;];
JupyterPrePrintFunction[v_]:=(WriteString[JupyterSTDOUT,"\nOut["<>ToString[$Line]<>"]= " <> JupyterReturnValue[v]<>"\n"]);

JupyterReturnValue[Null]:="null:";
JupyterReturnValue[v_Association]:= "string:"<> ExportString[InputForm@v, "Base64"];
(*JupyterReturnExpressionTeX[v_]:=( texstr=StringReplace[ToString[TeXForm[v]],"\n"->" "];
			       "tex:"<> ExportString[ToString[StringLength[texstr]]<>":"<> texstr<>":"<>
						  ToString[InputForm[v]], "BASE64"]);
*)
JupyterReturnImageFileSVG[v_]:= Module[{ fn = Jupyter`tmpdir <> "/session-figure"<>ToString[$Line]<>".svg"},
				    Export[fn, v, "SVG",ImageSize->Jupyter`imagewidth];
				    "svg:" <> fn
				   ];

JupyterReturnImageFileJPG[v_]:= Module[{ fn = Jupyter`tmpdir <> "/session-figure"<>ToString[$Line]<>".jpg"},
				    Export[fn,v,"jpg",ImageSize->Jupyter`imagewidth];
				    "jpg:" <> fn
				   ]

JupyterReturnImageFilePNG[v_]:= Module[{ fn = Jupyter`tmpdir <> "/session-figure"<>ToString[$Line]<>".png"},
				    Export[fn,v,"PNG",ImageSize->Jupyter`imagewidth];
				    "png:" <> fn
				   ]

JupyterReturnBase64SVG[v_]:= "svg:" <> "data:image/svg+xml;base64," <>
                                  StringReplace[ExportString[ExportString[v,"SVG", ImageSize->Jupyter`imagewidth],"Base64"],"\n"->""]

JupyterReturnBase64JPG[v_]:= "image:" <> "data:image/jpg;base64," <>
                                  StringReplace[ExportString[ExportString[v,"jpg", ImageSize->Jupyter`imagewidth],"Base64"],"\n"->""]

JupyterReturnBase64PNG[v_]:= "image:" <> "data:image/png;base64," <>
                                  StringReplace[ExportString[ExportString[v,"PNG", ImageSize->Jupyter`imagewidth],"Base64"],"\n"->""]



WMGraphics3DToJSON[g_Sphere]:= Module[{coords,rad},
				Switch[Length[g],
                                      0, coords={{0,0,0}};rad=1.,
				      1, coords=g[[1]];rad=1.,
				      2, coords=g[[1]];rad=g[[2]]
				      ];
			       	 If[Length[coords[[1]]]!=3,coords={coords}];
			         coords = Table[{c,Null},{c,coords}];
				 Return["{\"type\": \"sphere\", \"coords\":"<> ExportString[coords,"RawJSON","Compact"->True]  <>
				          ", \"radius\": "<> ExportString[rad,"RawJSON","Compact"->True]   <>
					  ", \"faceColor\": "<>facecolor<>"}"]];


WMGraphics3DToJSON[g_Point]:= Module[{coords,json},
				Switch[Length[g],
                                      0, coords={{0,0,0}},
				      1, coords=g[[1]]
				      ];
			       	 If[Length[coords[[1]]]!=3,coords={coords}];
			         coords = Table[{c,Null},{c,coords}];
				 json="{\"type\": \"point\", \"coords\":"<> ExportString[coords,"RawJSON","Compact"->True]  <>
				          ", \"color\": "<>facecolor<>"}";
				 Return[json]];



WMGraphics3DToJSON[g_Line]:= Module[{coords,json},
				Switch[Length[g],
                                      0, coords={{0,0,0}},
				      1, coords=g[[1]]
				      ];
			       	 If[Length[coords[[1]]]!=3,coords={coords}];
			         coords = Table[{c,Null},{c,coords}];
				 json="{\"type\": \"line\", \"coords\":"<> ExportString[coords,"RawJSON","Compact"->True]  <>
				          ", \"color\": "<>edgecolor<>"}";
				 Return[json]];




WMGraphics3DToJSON[g_Polygon]:= Module[{coords,json},
				Switch[Length[g],
                                      0, coords={{0,0,0}},
				      1, coords=g[[1]]
				      ];
			       	 If[Length[coords[[1]]]!=3,coords={coords}];
			         coords = Table[{c,Null},{c,coords}];
				 json="{\"type\": \"polygon\", \"coords\":"<> ExportString[coords,"RawJSON","Compact"->True]  <>
				          ", \"faceColor\": "<>facecolor<>"}";
				 Return[json]];



WMGraphics3DToJSON[g_Cuboid]:= Module[{coords,size,json},
				Switch[Length[g],
                                      0, coords={0,0,0};size={1,1,1},
				      1, coords={0,0,0};size=g[[1]],
				      2, coords=g[[1]];size=g[[2]]-g[[1]]
				      ];
			         coords = {{coords,Null}};
				 size = {{size,Null}};
				 json="{\"type\": \"cube\", \"position\":"<> ExportString[coords,"RawJSON","Compact"->True]  <>
				        ", \"size\": "<> ExportString[size,"RawJSON","Compact"->True] <>
				        ", \"faceColor\": "<>facecolor<>"}";
				 Return[json]];



WMGraphics3DToJSON[g_RGBColor]:= (facecolor=ExportString[List@@g//If[Length[#1]==3,Append[#1,1],#1]&,"RawJSON","Compact"->True]);




WMGraphics3DToJSON[g_EdgeForm]:= If[Length[g]>0, Do[Switch[dir[[0]],
                                    RGBColor,edgecolor=ExportString[List@@dir//If[Length[#1]==3,Append[#1,1],#1]&,"RawJSON","Compact"->True]
				    ],{dir,g[[1]]//If[g[[1]][[0]]===List,g[[1]],{g[[1]]}]}]]



WMGraphics3DToJSON[g_FaceForm]:= If[Length[g]>0, Do[Switch[dir[[0]],
                                    RGBColor,facecolor=ExportString[List@@dir//If[Length[#1]==3,Append[#1,1],#1]&,"RawJSON","Compact"->True]
				    ],{dir,g[[1]]//If[g[[1]][[0]]===List,g[[1]],{g[[1]]}]}]];




WMGraphics3DToJSON[g_Graphics3D]:= Module[{viewpoint, args, mmaelems,elem, mmaoptions,
					elems, threeelems,options,axes,ticks,range,extent,lighting},
   mmaelems = (Flatten[{Normal[g[[1]]]}]/.Annotation[args__]:>args[[1]]);
   mmaelems = If[mmaelems[[0]]===List,mmaelems,{mmaelems}];
   mmaelems = Flatten[mmaelems];
   facecolor = "[1.0,1.0,1.0,1.0]";
   edgecolor = "[0.0,0.0,0.0,1.0]";
   thickness = 1.;
   threeelems = {};
   Do[If[MemberQ[{Cuboid,Sphere,Point,Line,Polygon},elem[[0]]],AppendTo[threeelems,WMGraphics3DToJSON[elem]],WMGraphics3DToJSON[elem]],{elem,mmaelems}];
   If[Length[threeelems]==0,elems = "\"elements\":[]",
      elems = "\"elements\": [" <> threeelems[[1]]; threeelems=Drop[threeelems,1];
      While[Length[threeelems]!=0,elems = elems <> ", " <> threeelems[[1]]; threeelems=Drop[threeelems,1]];
      elems = elems <>"] "];
   lighting = "\"lighting\": [{\"color\": [0.3, 0.2, 0.4], \"type\": \"Ambient\"}, {\"color\": [0.8, 0.0, 0.0], \"position\": [2.0, 0.0, 2.0], \"type\": \"Directional\"}, {\"color\": [0.0, 0.8, 0.0], \"position\": [2.0, 2.0, 2.0], \"type\": \"Directional\"}, {\"color\": [0.0, 0.0, 0.8], \"position\": [0.0, 2.0, 2.0], \"type\": \"Directional\"}]";
   mmaoptions = If[Length[g]==2,g[[2]],{}];
   viewpoint = (ViewPoint/.mmaoptions);
   viewpoint = "\"viewpoint\": " <> If[ToString[viewpoint] == "ViewPoint", "[1.3, -2.4, 2.0]",
                                       ExportString[viewpoint,"RawJSON","Compact"->True]];
   axes = Axes/.mmaoptions;
   axes = If[axes[[0]]===List,axes,{axes,axes,axes}];
   axes = Table[If[ToString[a] == "True","true","false"],{a,axes}];
   axes = "\"hasaxes\": [" <> axes[[1]]<>", " <> axes[[2]]<>", " <> axes[[3]]<>"]";
   range = (PlotRange/.mmaoptions);
   range = If[ToString[range]=="PlotRange",{{0,1},{0,1},{0,1}},range];
   extent = "\"extent\": {\"xmin\":"<> 	ExportString[range[[1]][[1]],"RawJSON"]<>
                         ", \"xmax\": "<> ExportString[range[[1]][[2]],"RawJSON"]<>
			 ", \"ymin\": "<> ExportString[range[[2]][[1]],"RawJSON"]<>
			 ", \"ymax\": "<> ExportString[range[[2]][[2]],"RawJSON"]<>
			 ", \"zmin\": "<> ExportString[range[[3]][[1]],"RawJSON"]<>
			 ", \"zmax\": "<> ExportString[range[[3]][[2]],"RawJSON"]<>"}";
   ticks = (Ticks/.mmaoptions);
   ticks = If[ToString[Ticks]=="Ticks",{Automatic,Automatic,Automatic},Ticks];
   ticks = ExportString[
		  Table[
		  If[ToString[ticks[[r]]]=="Automatic",
		  {Table[k, {k,range[[r]][[1]],range[[r]][[2]],(range[[r]][[2]]-range[[r]][[1]])/10}],
                  Table[k, {k,range[[r]][[1]],range[[r]][[2]],(range[[r]][[2]]-range[[r]][[1]])/40}],
		  Table[ToString[k], {k,range[[r]][[1]],range[[r]][[2]],(range[[r]][[2]]-range[[r]][[1]])/10}]},
		  ticks[[r]]],{r,3}],
		  "RawJSON","Compact"->True];
   ticks = "\"ticks\": " <> ticks;
   Return["{"<> viewpoint <> ", " <> extent <> ", " <> elems  <> ", \"axes\": {"<> axes <>", " <> ticks <> "}, " <> lighting <>"}"]
];


MathicsGraphics3DToJSON[v_Graphics3D]:=(StringReplace[StringTake[v//MathMLForm//ToString,{43,-33}],"&quot;"->"\""]);
Graphics3DToJSON = If[Mathics, MathicsGraphics3DToJSON, WMGraphics3DToJSON];

JupyterReturn3DThree[v_]:= "3d:" <> "data:json/graphics3d;base64," <>
		      StringReplace[ExportString[Graphics3DToJSON[v],"Base64"] ,"\n"->""];

JupyterReturn3DImage[v_]:=JupyterReturnBase64PNG[v]  <>  ":" <> "- graphics3D -";
JupyterReturn3D=JupyterReturn3DImage;



JupyterReturnValue[v_Graphics]:= JupyterReturnImage[v]  <>  ":" <> "- graphics -";
JupyterReturnValue[v_Legended]:= JupyterReturnImage[v]  <>  ":" <> "- graphics -";
JupyterReturnValue[v_Graphics3D]:= JupyterReturn3D[v]  <>  ":" <> "- graphics3D -";
JupyterReturnValue[v_MatrixForm]:=JupyterReturnExpressionTeX[v];
JupyterReturnValue[v_ShowForm]:=(Print["showform\\"];JupyterReturnExpressionTeX[v[[1]]]);

JupyterReturnValue[v_]:= If[And[FreeQ[v,Graphics],FreeQ[v,Graphics3D]],
                            "string:"<> ExportString[InputForm@v//ToString, "Base64"],
			    (*else*)
			    JupyterReturnImage[v] <> ":" <>
			    ToString[InputForm[#1/.{Graphics[___]-> "- graphics -",
						    Graphics3D[___]-> "- graphics3D -"}]]
			   ]

JupyterReturnValue[v_Sound]:= "wav:"<> "data:audio/wav;base64," <> ExportString[ExportString[v,"wav"],"Base64"]

(*Definitions for Mathics*)
(*Print["Defining system dependent expressions for mathics"];*)
(*Support for functions that are not currently available in mathics*)
LoadModule["pymathics.asy"];
LoadModule["pymathics.matplotlib"];
Unprotect[WriteString];
WriteString[OutputStream["stdout", 1],x_]:=System`Print[x];
Protect[WriteString];
Global`Print[s_] := WriteString[OutputStream["stdout", 1],
"\nP:" <> ToString[StringLength[ToString[s]]] <> ":" <> ToString[s]<>"\n\n"];
(******)
JupyterReturnImage = JupyterReturnBase64SVG;
JupyterReturnValue[v_String]:= "string:"<> ExportString[v, "Base64"];
JupyterReturnExpressionTeX[v_]:=( texstr=StringReplace[ToString[TeXForm[v]],"\n"->" "];
					"tex:"<> ExportString[ToString[StringLength[texstr]]<>":"<> texstr<>":"<>
							ToString[InputForm[v]] , "Base64"]);
JupyterSTDOUT = OutputStream["stdout", 1];
JupyterMessage[m_MessageName, vars___] :=
  WriteString[OutputStream["stdout", 1], BuildMessage[m, vars]];
BuildMessage[something___] := "";
BuildMessage[$Off[], vals___] := "";
BuildMessage[m_MessageName, vals___] := Module[{lvals, msgs, msg},
					       lvals = List@vals;
					       lvals = ToString[#1, InputForm] & /@ lvals;
					       lvals = Sequence @@ lvals;
					       msgs = Messages[m[[1]] // Evaluate];
							       If[Length[msgs] == 0, Return[""]];
							       msg = m /. msgs;
							       msg = ToString[m]<>": "<>ToString[StringForm[msg, lvals]];
							       msg = "\nM:" <> ToString[StringLength[msg]] <> ":" <> msg <> "\n"
							       ];

(*Redefine Preprint Function*)
System`$PrePrint:=JupyterPrePrintFunction
(*Redefine Message*)
Unprotect[Message];
Message[m_MessageName, vals___] :=
WriteString[OutputStream["stdout", 1], BuildMessage[m, vals]];
Unprotect[Message];
Print["Done"];
End[];
EndPackage[];

