<%@ Page language="c#" src="index.aspx.cs" AutoEventWireup="false" Inherits="UindexWeb.Search"%>
<%@ Register Src="ctrl.top.ascx" TagName="top" TagPrefix="uc1" %>
<%@ Register Src="ctrl.foot.ascx" TagName="foot" TagPrefix="myctrl"%><!--Author:Uindex,13:24 2006-10-2-->
<!--Copyright (C) 1982-2006 By Uindex-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=gb2312">
<title>UindexWeb搜索_<%=Query%></title>
<STYLE><!--
body,td,.p1,.p2,.i{font-family:arial}
body{margin:0px 0 0 0;background-color:#fff;color:#000;}
table{border:0}
TD{FONT-SIZE:9pt;LINE-HEIGHT:18px;}
.f14{FONT-SIZE:14px}
.f10{font-size:10.5pt}
.f16{font-size:16px;font-family:Arial}
.c{color:#7777CC;}
.p1{LINE-HEIGHT:120%;margin-left:-12pt}
.p2{width:100%;LINE-HEIGHT:120%;margin-left:-12pt}
.i{font-size:16px}
.t{COLOR:#0000cc;TEXT-DECORATION:none}
a.t:hover{TEXT-DECORATION:underline}
.p{padding-left:18px;font-size:14px;word-spacing:4px;}
.f{line-height:120%;font-size:100%;width:32em;padding-left:15px;word-break:break-all;word-wrap:break-word;}
.h{margin-left:8px;width:100%}
.s{width:8%;padding-left:10px; height:25px;}
.m,a.m:link{COLOR:#666666;font-size:100%;}
a.m:visited{COLOR:#660066;}
.g{color:#008000; font-size:12px;}
.r{ word-break:break-all;cursor:hand;width:225px;}
.bi {background-color:#D9E1F7;height:20px;margin-bottom:12px}
.pl{padding-left:3px;height:8px;padding-right:2px;font-size:14px;}
.Tit{height:21px; font-size:14px;}
.fB{ font-weight:bold;}
.mo,a.mo:link,a.mo:visited{COLOR:#666666;font-size:100%;line-height:10px;}
.htb{margin-bottom:5px;}
#ft{clear:both;line-height:20px;background:#E6E6E6;text-align:center}
#ft,#ft *{color:#77C;font-size:12px;font-family:Arial}
#ft span{color:#666}
--></STYLE>
<script language="javascript">
   if(top.location != self.location){top.location=self.location;}
</script>
</head>
<body onload="document.Form1.reset();" link="#261CDC">
<form id="Form1" name="Form1" method="post" runat="server">
<uc1:top ID="top1" runat="server" />
<table width="100%" height="70" align="center" cellpadding="0" cellspacing="0">
   <tr valign=middle>
   <td width="100%" style="padding-left:8px;width:137px;" nowrap>
   <img src="logo.jpg">
   </td>
   <td>&nbsp;&nbsp;&nbsp;</td>
   <td style="width: 100%">
   <table cellspacing="0" cellpadding="0">
   <tr><td valign="top" nowrap>
   <asp:TextBox ID="TextBoxQuery" class="i" runat="server" MaxLength="30"></asp:TextBox>
       &nbsp;<asp:Button ID="ButtonSearch" runat="server" Text="UindexWeb搜索" />&nbsp;&nbsp;&nbsp;</td>
   <td valign="middle" nowrap>
   </td></tr></table>
   </td>
   <td></td>
   </tr>
</table>
<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" class="bi">
   <tr>
   <td nowrap></td>
   <td align="right" nowrap><%# Summary %>&nbsp;&nbsp;&nbsp;&nbsp;</td>
   </tr>
</table>
<table width="25%" border="0" cellpadding="0" cellspacing="0" align="right"><tr>
   <td align="left" style="padding-right:10px">
   <div class="r">
   <a href='#' target='_blank'>
   <font size="3">右边栏广告</font>
   </a><br>
   <span id="Span5"><font size="-1" color="#000000">广告说明文字</font></span>
   </div><br>
   <a href='#' target='_blank'>访问通用网址<font color=#C60A00><%=Query%></font></a><br><a href='#' target='_blank'>更多<font color=#C60A00><%=Query%></font>在慧聪，快查看</a><br>
   </div><br>
   <table border=0 cellpadding=0 cellspacing=0  style="width:240px;border-left: #EFF2FA 1px solid; border-right: #EFF2FA 1px solid;border-bottom: #EFF2FA 1px solid; font-size: 12px; color: #333333;background-color: #EFF2FA;">
      <tr>
         <td style="table-layout:fixed;word-break:break-all;border-top: #7593E5 1px solid;background-color: #EFF2FA;padding-left:10px;line-height:24px;">
         <a href="#" target=_blank><font style="font-size:9pt">发布/查看关于<font color="#C60A00"><%=Query%></font>的留言 XXX 篇</font></a>
         </td>
      </tr>
   </table>
   <DIV id=ScriptDiv></DIV>
   </td>
   </tr>
</table>
<asp:repeater id=Repeater3 runat="server" DataSource="<%# Results %>">
   <ItemTemplate>
   <table border="0" cellpadding="0" cellspacing="0">
   <tr>
   <td class=f>
   <a href="<%# DataBinder.Eval(Container.DataItem, "WPUrl")%>" target="_blank"><font size="3"><%# DataBinder.Eval(Container.DataItem, "WPTitle")%></font></a>
   <br><font size=-1><%# DataBinder.Eval(Container.DataItem, "WPContent")%>... <br><font color=#008000><%# DataBinder.Eval(Container.DataItem, "WPUrl")%></font>
   <br></font>
   </td>
   </tr>
   </table>
   <br>
   </ItemTemplate>
</asp:repeater>

<br>
<div class="p"><asp:repeater id="Repeater4" runat="server" DataSource="<%# Paging %>">
   <ItemTemplate><%# DataBinder.Eval(Container.DataItem, "html") %></ItemTemplate>
</asp:repeater></div><br>

<div style="background-color:#EFF2FA;height:45px;width:100%;clear:both">
<table width="96%" height="100%" border="0" align="center" cellpadding="0" cellspacing="0">
   <tr><td style="font-size:14px;font-weight:bold;width:70px;">相关搜索</td>
   <td rowspan="1" valign="middle">
   <table border="0" cellpadding="0" cellspacing="0"><tr>
      <td nowrap class="f14"><a href="index.aspx?q=<%=Query%>"><%=Query%></a></td>
      </tr>
   </table>
   </td>
   </tr>
</table>
</div><br>
<table cellpadding="0" cellspacing="0" style="margin-left:18px;height:60px;">
</table>
<myctrl:foot ID="foot1" runat="server" />
</form>
</body>
</html>