//-------------------------------------------------------------
//    UindexWeb中文分词及索引建立程序
//
//编写环境:VisualC#.Net 2005+WindowsXP
//编写时间:2006年10月10日
//作    者:Jun Zeng
//联系方式:webmaster@opencpu.com
//-------------------------------------------------------------
using System;
using System.Threading;
//创建索引花费很多时间,界面卡的严重,所以使用线程模式.
using System.IO;
using System.Drawing;
using System.Text;
using System.Collections;
using System.ComponentModel;
using System.Runtime.InteropServices;
//这个是为了实现LoadLibrary动态加载DLL.
using System.Windows.Forms;
using System.Data;
using System.Data.OleDb;
//目前oledb可以支持DB2,SQLserver,Oracle,Sybase,Access等数据库格式.
using Lucene.Net;
using Lucene.Net.Documents;
using Lucene.Net.Index;
using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Standard;

namespace UindexWebIndexer
{
	///----------------------------------------------
	/// 应用程序主窗口类
	///----------------------------------------------
	public class mainform : System.Windows.Forms.Form
	{
		//----------------------------------------------
		// 实现IniReadValue函数
		//----------------------------------------------
		[DllImport("kernel32")]
		private static extern int GetPrivateProfileString(string section,
			string key,string def, StringBuilder retVal,
			int size,string filePath);
		public string IniReadValue(string Section,string Key)
		{
			StringBuilder temp = new StringBuilder(255);
			int i = GetPrivateProfileString(Section,Key,"",temp,
                255, ConfigFile.Text);
			return temp.ToString();
		}
		//----------------------------------------------
		// 实现中文分词函数,这个是从CSW的C语言接口导出,使用时一定要处理可能的异常
		//----------------------------------------------
		[DllImport("CSW.dll")]
		//原文如下:
		//char* (* lpSplitFun)(char *,long,char *);           1:char *返回标准NULL结尾字符串.2:(* lpSplitFun)指向函数的指针(即地址)后面是参数(如果是delphi调用对应pchar或widestring,注意区分大小写)
		//splitFun = (lpSplitFun)GetProcAddress(hDll,"Split");转换为lpSplitFun型
		public static extern string Split(string h, int m, string c);
		//这里有个概念工作目录和数据目录,他的现象是如果你选择了Access数据库,那就使用数据库目录放索引文件,否则放在当前目录下
		private string workpath,constr;
		private bool needtrycsw=false;//需要尝试CSW,如果3个必备文件不全则默认不尝试
		private bool terminated=false;//程序结束标志,给线程用的,免得他再访问已释放的资源
		private IndexWriter writer;   //Lucene索引写入器,这里直接给他字符串,不像演示程序那样通过文件
		//界面部分,拖拉机干的活儿
		private System.Windows.Forms.StatusBar BottomStatusBar;
		private System.Windows.Forms.StatusBarPanel statusBarPanel1;
		private System.Windows.Forms.StatusBarPanel statusBarPanel2;
		private System.Windows.Forms.StatusBarPanel statusBarPanel3;
		private System.Windows.Forms.GroupBox groupBox1;
		private System.Windows.Forms.PictureBox PicUindexLogo;
		private System.Windows.Forms.Label CommonTips;
        private System.Windows.Forms.GroupBox groupBox2;
		private System.Windows.Forms.GroupBox groupBox3;
		private System.Windows.Forms.Button BtnNext;
        private System.Windows.Forms.OpenFileDialog SelectConfigFile;
        private TabControl MainTabs;
        private TabPage tabPage1;
        private TabPage tabPage2;
        private TabPage tabPage3;
        private TextBox status;
        private Button BtnPreview;
        private GroupBox groupBox4;
        private TextBox ConfigFile;
        private Button BtnSelectConfig;
        private GroupBox groupBox5;
        private TextBox OutputDir;
        private Button SelectOutDir;
        private Label LblConfigTips;
        private Label MissConfigFile;
        private RadioButton UseCSW;
        private RadioButton UseLucene;
        private Label LblCSWTips;
        private FolderBrowserDialog SelectOutputDir;
		/// <summary>
		/// 必需的设计器变量。
		/// </summary>
		private System.ComponentModel.Container components = null;

		public mainform()
		{
			//mainform的构造函数override;
			InitializeComponent();
		}
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null)
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}

		#region Windows 窗体设计器生成的代码
		/// <summary>
		/// 设计器支持所需的方法 - 不要使用代码编辑器修改
		/// 此方法的内容。
		/// </summary>
		private void InitializeComponent()
		{
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(mainform));
            this.BottomStatusBar = new System.Windows.Forms.StatusBar();
            this.statusBarPanel1 = new System.Windows.Forms.StatusBarPanel();
            this.statusBarPanel2 = new System.Windows.Forms.StatusBarPanel();
            this.statusBarPanel3 = new System.Windows.Forms.StatusBarPanel();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.CommonTips = new System.Windows.Forms.Label();
            this.PicUindexLogo = new System.Windows.Forms.PictureBox();
            this.SelectConfigFile = new System.Windows.Forms.OpenFileDialog();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.MainTabs = new System.Windows.Forms.TabControl();
            this.tabPage1 = new System.Windows.Forms.TabPage();
            this.groupBox4 = new System.Windows.Forms.GroupBox();
            this.MissConfigFile = new System.Windows.Forms.Label();
            this.LblConfigTips = new System.Windows.Forms.Label();
            this.ConfigFile = new System.Windows.Forms.TextBox();
            this.BtnSelectConfig = new System.Windows.Forms.Button();
            this.tabPage2 = new System.Windows.Forms.TabPage();
            this.groupBox5 = new System.Windows.Forms.GroupBox();
            this.UseCSW = new System.Windows.Forms.RadioButton();
            this.UseLucene = new System.Windows.Forms.RadioButton();
            this.LblCSWTips = new System.Windows.Forms.Label();
            this.tabPage3 = new System.Windows.Forms.TabPage();
            this.OutputDir = new System.Windows.Forms.TextBox();
            this.SelectOutDir = new System.Windows.Forms.Button();
            this.status = new System.Windows.Forms.TextBox();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.BtnPreview = new System.Windows.Forms.Button();
            this.BtnNext = new System.Windows.Forms.Button();
            this.SelectOutputDir = new System.Windows.Forms.FolderBrowserDialog();
            ((System.ComponentModel.ISupportInitialize)(this.statusBarPanel1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.statusBarPanel2)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.statusBarPanel3)).BeginInit();
            this.groupBox1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.PicUindexLogo)).BeginInit();
            this.groupBox2.SuspendLayout();
            this.MainTabs.SuspendLayout();
            this.tabPage1.SuspendLayout();
            this.groupBox4.SuspendLayout();
            this.tabPage2.SuspendLayout();
            this.groupBox5.SuspendLayout();
            this.tabPage3.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.SuspendLayout();
            //
            // BottomStatusBar
            //
            this.BottomStatusBar.Location = new System.Drawing.Point(0, 310);
            this.BottomStatusBar.Name = "BottomStatusBar";
            this.BottomStatusBar.Panels.AddRange(new System.Windows.Forms.StatusBarPanel[] {
            this.statusBarPanel1,
            this.statusBarPanel2,
            this.statusBarPanel3});
            this.BottomStatusBar.ShowPanels = true;
            this.BottomStatusBar.Size = new System.Drawing.Size(489, 22);
            this.BottomStatusBar.TabIndex = 0;
            //
            // statusBarPanel1
            //
            this.statusBarPanel1.BorderStyle = System.Windows.Forms.StatusBarPanelBorderStyle.None;
            this.statusBarPanel1.Name = "statusBarPanel1";
            this.statusBarPanel1.Text = "当前状态:";
            this.statusBarPanel1.Width = 70;
            //
            // statusBarPanel2
            //
            this.statusBarPanel2.Name = "statusBarPanel2";
            this.statusBarPanel2.Text = "准备就绪";
            this.statusBarPanel2.Width = 235;
            //
            // statusBarPanel3
            //
            this.statusBarPanel3.Alignment = System.Windows.Forms.HorizontalAlignment.Right;
            this.statusBarPanel3.Name = "statusBarPanel3";
            this.statusBarPanel3.Text = "(c) Uindex ";
            this.statusBarPanel3.Width = 80;
            //
            // groupBox1
            //
            this.groupBox1.Controls.Add(this.CommonTips);
            this.groupBox1.Controls.Add(this.PicUindexLogo);
            this.groupBox1.Location = new System.Drawing.Point(2, 0);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(150, 303);
            this.groupBox1.TabIndex = 1;
            this.groupBox1.TabStop = false;
            //
            // CommonTips
            //
            this.CommonTips.Location = new System.Drawing.Point(8, 64);
            this.CommonTips.Name = "CommonTips";
            this.CommonTips.Size = new System.Drawing.Size(134, 232);
            this.CommonTips.TabIndex = 1;
            this.CommonTips.Text = "  请选择UindexWeb的配置文件,单击下一步,启动全文检索引擎。";
            //
            // PicUindexLogo
            //
            this.PicUindexLogo.Image = ((System.Drawing.Image)(resources.GetObject("PicUindexLogo.Image")));
            this.PicUindexLogo.Location = new System.Drawing.Point(2, 10);
            this.PicUindexLogo.Name = "PicUindexLogo";
            this.PicUindexLogo.Size = new System.Drawing.Size(140, 50);
            this.PicUindexLogo.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.PicUindexLogo.TabIndex = 0;
            this.PicUindexLogo.TabStop = false;
            //
            // SelectConfigFile
            //
            this.SelectConfigFile.FileName = "UindexWeb.INI";
            this.SelectConfigFile.Filter = "INI配置文件(*.INI)|*.ini|所有类型|*.*";
            this.SelectConfigFile.Title = "请指定配置文件的位置:";
            this.SelectConfigFile.FileOk += new System.ComponentModel.CancelEventHandler(this.SelectConfigFile_FileOk);
            //
            // groupBox2
            //
            this.groupBox2.Controls.Add(this.MainTabs);
            this.groupBox2.Controls.Add(this.groupBox3);
            this.groupBox2.Location = new System.Drawing.Point(151, 0);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(334, 303);
            this.groupBox2.TabIndex = 4;
            this.groupBox2.TabStop = false;
            //
            // MainTabs
            //
            this.MainTabs.Controls.Add(this.tabPage1);
            this.MainTabs.Controls.Add(this.tabPage2);
            this.MainTabs.Controls.Add(this.tabPage3);
            this.MainTabs.Location = new System.Drawing.Point(8, 13);
            this.MainTabs.Name = "MainTabs";
            this.MainTabs.SelectedIndex = 0;
            this.MainTabs.Size = new System.Drawing.Size(322, 237);
            this.MainTabs.TabIndex = 8;
            this.MainTabs.SelectedIndexChanged += new System.EventHandler(this.MainTabs_SelectedIndexChanged);
            //
            // tabPage1
            //
            this.tabPage1.Controls.Add(this.groupBox4);
            this.tabPage1.Location = new System.Drawing.Point(4, 21);
            this.tabPage1.Name = "tabPage1";
            this.tabPage1.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage1.Size = new System.Drawing.Size(314, 212);
            this.tabPage1.TabIndex = 0;
            this.tabPage1.Text = "配置文件";
            this.tabPage1.UseVisualStyleBackColor = true;
            //
            // groupBox4
            //
            this.groupBox4.Controls.Add(this.MissConfigFile);
            this.groupBox4.Controls.Add(this.LblConfigTips);
            this.groupBox4.Controls.Add(this.ConfigFile);
            this.groupBox4.Controls.Add(this.BtnSelectConfig);
            this.groupBox4.Location = new System.Drawing.Point(4, 3);
            this.groupBox4.Name = "groupBox4";
            this.groupBox4.Size = new System.Drawing.Size(304, 203);
            this.groupBox4.TabIndex = 8;
            this.groupBox4.TabStop = false;
            this.groupBox4.Text = "指定配置文件";
            //
            // MissConfigFile
            //
            this.MissConfigFile.Location = new System.Drawing.Point(8, 154);
            this.MissConfigFile.Name = "MissConfigFile";
            this.MissConfigFile.Size = new System.Drawing.Size(286, 17);
            this.MissConfigFile.TabIndex = 11;
            //
            // LblConfigTips
            //
            this.LblConfigTips.Location = new System.Drawing.Point(7, 24);
            this.LblConfigTips.Name = "LblConfigTips";
            this.LblConfigTips.Size = new System.Drawing.Size(287, 130);
            this.LblConfigTips.TabIndex = 10;
            this.LblConfigTips.Text = "        这是UindexWeb运行时用于设置工作环境的文件，向导通过读取这个文件来确定数据来源。";
            //
            // ConfigFile
            //
            this.ConfigFile.BackColor = System.Drawing.SystemColors.Control;
            this.ConfigFile.Location = new System.Drawing.Point(7, 172);
            this.ConfigFile.Name = "ConfigFile";
            this.ConfigFile.Size = new System.Drawing.Size(223, 21);
            this.ConfigFile.TabIndex = 9;
            this.ConfigFile.Text = "指定UindexWeb.INI...";
            //
            // BtnSelectConfig
            //
            this.BtnSelectConfig.FlatStyle = System.Windows.Forms.FlatStyle.Popup;
            this.BtnSelectConfig.Location = new System.Drawing.Point(230, 172);
            this.BtnSelectConfig.Name = "BtnSelectConfig";
            this.BtnSelectConfig.Size = new System.Drawing.Size(64, 22);
            this.BtnSelectConfig.TabIndex = 8;
            this.BtnSelectConfig.Text = "选择...";
            this.BtnSelectConfig.Click += new System.EventHandler(this.SetConfigFile_Click);
            //
            // tabPage2
            //
            this.tabPage2.Controls.Add(this.groupBox5);
            this.tabPage2.Location = new System.Drawing.Point(4, 21);
            this.tabPage2.Name = "tabPage2";
            this.tabPage2.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage2.Size = new System.Drawing.Size(314, 212);
            this.tabPage2.TabIndex = 1;
            this.tabPage2.Text = "中文分词";
            this.tabPage2.UseVisualStyleBackColor = true;
            //
            // groupBox5
            //
            this.groupBox5.Controls.Add(this.UseCSW);
            this.groupBox5.Controls.Add(this.UseLucene);
            this.groupBox5.Controls.Add(this.LblCSWTips);
            this.groupBox5.Location = new System.Drawing.Point(4, 3);
            this.groupBox5.Name = "groupBox5";
            this.groupBox5.Size = new System.Drawing.Size(304, 203);
            this.groupBox5.TabIndex = 9;
            this.groupBox5.TabStop = false;
            this.groupBox5.Text = "选择分词组件";
            //
            // UseCSW
            //
            this.UseCSW.AutoSize = true;
            this.UseCSW.Checked = true;
            this.UseCSW.Location = new System.Drawing.Point(155, 171);
            this.UseCSW.Name = "UseCSW";
            this.UseCSW.Size = new System.Drawing.Size(107, 16);
            this.UseCSW.TabIndex = 13;
            this.UseCSW.TabStop = true;
            this.UseCSW.Text = "CSW中文分词(&C)";
            this.UseCSW.UseVisualStyleBackColor = true;
            this.UseCSW.CheckedChanged += new System.EventHandler(this.UseCSW_CheckedChanged);
            //
            // UseLucene
            //
            this.UseLucene.AutoSize = true;
            this.UseLucene.Location = new System.Drawing.Point(16, 171);
            this.UseLucene.Name = "UseLucene";
            this.UseLucene.Size = new System.Drawing.Size(101, 16);
            this.UseLucene.TabIndex = 12;
            this.UseLucene.TabStop = true;
            this.UseLucene.Text = "Lucene默认(&L)";
            this.UseLucene.UseVisualStyleBackColor = true;
            //
            // LblCSWTips
            //
            this.LblCSWTips.Location = new System.Drawing.Point(7, 24);
            this.LblCSWTips.Name = "LblCSWTips";
            this.LblCSWTips.Size = new System.Drawing.Size(287, 85);
            this.LblCSWTips.TabIndex = 11;
            this.LblCSWTips.Text = "        目前UindexWeb发布向导支持Lucene自带的分词和CSW中文分词组件，如需其他分词组件支持请联系作者。";
            //
            // tabPage3
            //
            this.tabPage3.Controls.Add(this.OutputDir);
            this.tabPage3.Controls.Add(this.SelectOutDir);
            this.tabPage3.Controls.Add(this.status);
            this.tabPage3.Location = new System.Drawing.Point(4, 21);
            this.tabPage3.Name = "tabPage3";
            this.tabPage3.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage3.Size = new System.Drawing.Size(314, 212);
            this.tabPage3.TabIndex = 2;
            this.tabPage3.Text = "全文索引";
            this.tabPage3.UseVisualStyleBackColor = true;
            //
            // OutputDir
            //
            this.OutputDir.BackColor = System.Drawing.SystemColors.Control;
            this.OutputDir.Location = new System.Drawing.Point(11, 176);
            this.OutputDir.Name = "OutputDir";
            this.OutputDir.ShortcutsEnabled = false;
            this.OutputDir.Size = new System.Drawing.Size(223, 21);
            this.OutputDir.TabIndex = 12;
            this.OutputDir.Text = "指定全文索引输出目录...";
            //
            // SelectOutDir
            //
            this.SelectOutDir.FlatStyle = System.Windows.Forms.FlatStyle.Popup;
            this.SelectOutDir.Location = new System.Drawing.Point(234, 176);
            this.SelectOutDir.Name = "SelectOutDir";
            this.SelectOutDir.Size = new System.Drawing.Size(64, 21);
            this.SelectOutDir.TabIndex = 11;
            this.SelectOutDir.Text = "选择...";
            this.SelectOutDir.Click += new System.EventHandler(this.SelectOutDir_Click);
            //
            // status
            //
            this.status.Location = new System.Drawing.Point(5, 4);
            this.status.Multiline = true;
            this.status.Name = "status";
            this.status.ReadOnly = true;
            this.status.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.status.Size = new System.Drawing.Size(302, 165);
            this.status.TabIndex = 10;
            this.status.Text = "准备就绪";
            //
            // groupBox3
            //
            this.groupBox3.Controls.Add(this.BtnPreview);
            this.groupBox3.Controls.Add(this.BtnNext);
            this.groupBox3.Location = new System.Drawing.Point(8, 248);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(317, 48);
            this.groupBox3.TabIndex = 7;
            this.groupBox3.TabStop = false;
            //
            // BtnPreview
            //
            this.BtnPreview.FlatStyle = System.Windows.Forms.FlatStyle.Popup;
            this.BtnPreview.ImageAlign = System.Drawing.ContentAlignment.BottomLeft;
            this.BtnPreview.Location = new System.Drawing.Point(37, 16);
            this.BtnPreview.Name = "BtnPreview";
            this.BtnPreview.Size = new System.Drawing.Size(120, 23);
            this.BtnPreview.TabIndex = 1;
            this.BtnPreview.Text = "上一步(&P)";
            this.BtnPreview.Click += new System.EventHandler(this.GoBack_Click);
            //
            // BtnNext
            //
            this.BtnNext.FlatStyle = System.Windows.Forms.FlatStyle.Popup;
            this.BtnNext.ImageAlign = System.Drawing.ContentAlignment.BottomLeft;
            this.BtnNext.Location = new System.Drawing.Point(164, 16);
            this.BtnNext.Name = "BtnNext";
            this.BtnNext.Size = new System.Drawing.Size(120, 23);
            this.BtnNext.TabIndex = 0;
            this.BtnNext.Text = "下一步(&N)";
            this.BtnNext.Click += new System.EventHandler(this.GotoNextPage_Click);
            //
            // SelectOutputDir
            //
            this.SelectOutputDir.RootFolder = System.Environment.SpecialFolder.MyComputer;
            //
            // mainform
            //
            this.AutoScaleBaseSize = new System.Drawing.Size(6, 14);
            this.ClientSize = new System.Drawing.Size(489, 332);
            this.Controls.Add(this.groupBox2);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.BottomStatusBar);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.Fixed3D;
            this.MaximizeBox = false;
            this.Name = "mainform";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "UindexWeb发布向导";
            this.Closing += new System.ComponentModel.CancelEventHandler(this.mainform_Closing);
            this.Load += new System.EventHandler(this.MainForm_Load);
            ((System.ComponentModel.ISupportInitialize)(this.statusBarPanel1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.statusBarPanel2)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.statusBarPanel3)).EndInit();
            this.groupBox1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.PicUindexLogo)).EndInit();
            this.groupBox2.ResumeLayout(false);
            this.MainTabs.ResumeLayout(false);
            this.tabPage1.ResumeLayout(false);
            this.groupBox4.ResumeLayout(false);
            this.groupBox4.PerformLayout();
            this.tabPage2.ResumeLayout(false);
            this.groupBox5.ResumeLayout(false);
            this.groupBox5.PerformLayout();
            this.tabPage3.ResumeLayout(false);
            this.tabPage3.PerformLayout();
            this.groupBox3.ResumeLayout(false);
            this.ResumeLayout(false);

		}
		#endregion

		/// 应用程序的主入口点。
		[STAThread]
		static void Main()
		{
            Application.EnableVisualStyles();
            Application.Run(new mainform());
		}

		private void MainForm_Load(object sender, System.EventArgs e)
		{
			workpath                    = GetPath(Application.ExecutablePath);
            SelectOutputDir.SelectedPath  = workpath;
			SelectConfigFile.InitialDirectory = workpath;
            if (File.Exists(workpath + "\\UindexWeb.ini"))
            {
                ConfigFile.Text = workpath + "\\UindexWeb.ini";
                OutputDir.Text = workpath;
            }
			//在当前目录下查找CSW必须的三个文件,看是否存在,存在则尝试使用它们的中文分词
			if(File.Exists(workpath+"\\CSW.dll")&&File.Exists(workpath+"\\csplitword.dct")&&File.Exists(workpath+"\\csplitword.idx")){
				needtrycsw=true;
			}
            UseLucene.Checked = !needtrycsw;
            UseCSW.Checked    = needtrycsw;
		}
        private delegate void efreshui(string msg);
        private efreshui myfreshui = null;
        private efreshui myComplete = null;
        private void freshui(string msg)
        {
            if(status.Lines.GetLength(0)>100)status.Text="";
               status.AppendText(msg);
        }

        private void ThreadComplete(string msg)
        {
            BottomStatusBar.Panels[1].Text = msg;

            if (msg.IndexOf("失败") <= 0)
            {
                MessageBox.Show("已经成功的为UindexWeb建立了全文索引。\n\n请将 " + OutputDir.Text + "\\UindexWeb 目录连同ASP.Net网页一起上传至服务器。", "索引完成", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            else
            {
                MessageBox.Show(msg, "索引建立失败", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void IndexThread()
		{
			int    recid=0;

            string WPTitle = "";
            string WPRealTitle = "";
            string WPContent = " ";
            string WPUrl = " ";

            string mySelectQuery = "SELECT WPTitle,WPRealTitle,WPContent,WPUrl FROM UindexWeb_WebPage";
            OleDbConnection myConnection = new OleDbConnection(constr);
			OleDbCommand myCommand = new OleDbCommand(mySelectQuery,myConnection);
			myConnection.Open();
			OleDbDataReader myReader;

            try
            {
                myReader = myCommand.ExecuteReader();
            }catch(Exception E)
            {
                this.Invoke(this.myComplete, new object[] { "索引建立失败：" + E.Message });
                return;
            }
			while (myReader.Read()&&(!terminated))
			{
				recid+=1;
                WPRealTitle = myReader.GetString(1);
				if(((recid % 50)==0)&&(!terminated))
				{
                    this.Invoke(this.myfreshui, new object[] { recid.ToString() + ": " + WPRealTitle + "\n" });
				}

				//字符串型数据
				if(!myReader.IsDBNull(0))
                    WPTitle = myReader.GetString(0);
				if(!myReader.IsDBNull(2))
                    WPContent = myReader.GetString(2);
				if(!myReader.IsDBNull(3))
                    WPUrl = myReader.GetString(3);

                AddRecord(WPTitle, WPRealTitle, WPContent, WPUrl);
			}
			myReader.Close();
			myConnection.Close();
			writer.Optimize();
			writer.Close();
            if(!terminated){
                this.Invoke(this.myComplete, new object[] { "索引成功建立。" });
			}
		}

		private void SetConfigFile_Click(object sender, System.EventArgs e)
		{
            if (IniReadValue("UindexWeb", "ConnStr") == null || IniReadValue("UindexWeb", "ConnStr").Length == 0)
			{
				SelectConfigFile.ShowDialog();}
			else
			{
				if (MessageBox.Show ("当前数据库已经存在,要重新指定一个数据库吗?", "是否删除",
						MessageBoxButtons.YesNo, MessageBoxIcon.Question)
						== DialogResult.Yes)
					{
						SelectConfigFile.ShowDialog();
					}
			}
		}

		private void SelectConfigFile_FileOk(object sender, System.ComponentModel.CancelEventArgs e)
		{
            ConfigFile.Text  = SelectConfigFile.FileName;
            if (null == OutputDir.Text || OutputDir.Text.Length == 0 || !Directory.Exists(OutputDir.Text))
            {
                OutputDir.Text = GetPath(ConfigFile.Text);
                BottomStatusBar.Panels[1].Text = OutputDir.Text;
            }
            MissConfigFile.Text = "";
            MissConfigFile.ForeColor = Color.Black;
            ConfigFile.ForeColor = MissConfigFile.ForeColor;
		}

        private void AddRecord(string WPTitle, string WPRealTitle, string WPContent, string WPUrl)
        {
            Document doc = new Document();

            //--------------------------------------------------------
            //首先判断是不是需要中文分词,并分词索引
            //--------------------------------------------------------
            if (UseCSW.Checked)
            {
                try
                {
                    doc.Add(Field.UnStored("iTitle", Split(WPTitle, 0, workpath)));
                    doc.Add(Field.UnStored("iContent", Split(WPContent, 0, workpath)));
                }
                catch
                {
                    doc.Add(Field.UnStored("iTitle", WPTitle));
                    doc.Add(Field.UnStored("iContent", WPContent));
                }
            }
            else
            {
                doc.Add(Field.UnStored("iTitle", WPTitle));
                doc.Add(Field.UnStored("iContent", WPContent));
            }
            //--------------------------------------------------------
            //网页附加信息且可能被搜索
            //--------------------------------------------------------
            doc.Add(Field.UnIndexed("WPUrl", WPUrl));
            doc.Add(Field.UnIndexed("WPTitle", WPRealTitle));
            doc.Add(Field.UnIndexed("WPContent", WPContent));

            writer.AddDocument(doc);
        }

		private void GotoNextPage_Click(object sender, System.EventArgs e)
		{
            if (null == ConfigFile.Text || ConfigFile.Text.Length == 0 || !File.Exists(ConfigFile.Text))
            {
                MissConfigFile.Text = "配置文件地址不正确！";
                MainTabs.SelectedIndex = 0;
                MissConfigFile.ForeColor = Color.Red;
                ConfigFile.ForeColor = MissConfigFile.ForeColor;
                return;
            }
            else {
                MissConfigFile.Text = "";
                MissConfigFile.ForeColor = Color.Black;
                ConfigFile.ForeColor = MissConfigFile.ForeColor;
            }
            if (MainTabs.SelectedIndex > 0 && needtrycsw && UseCSW.Checked)
            {
                SetUiEnable(false);
                string test = Split("Uindex中文搜索引擎", 0, workpath);
                if (null == test || test.IndexOf("已超过有效期") > 0)
                {
                    MessageBox.Show(test, "CSW过期",
                        MessageBoxButtons.OK, MessageBoxIcon.Question);
                    MainTabs.SelectedIndex = 1;
                    UseCSW.Checked = false;
                    UseLucene.Checked = true;
                    SetUiEnable(true);
                    return;
                }
                SetUiEnable(true);
            }
            if (MainTabs.SelectedIndex == 2 && (null == OutputDir.Text || OutputDir.Text.Length == 0 || !Directory.Exists(OutputDir.Text)))
            {
                OutputDir.Text = GetPath(ConfigFile.Text);
                BottomStatusBar.Panels[1].Text = OutputDir.Text;
            }
            if (MainTabs.SelectedIndex < (MainTabs.TabCount - 1))
            {
                MainTabs.SelectedIndex++;
            }
            else
            {
                if ((constr == null || constr.Trim().Length == 0) && (null == IniReadValue("UindexWeb", "ConnStr") || IniReadValue("UindexWeb", "ConnStr").Length == 0))
                {
                    constr = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + GetPath(ConfigFile.Text) + "\\UindexWeb.mdb;Persist Security Info=False";
                }
                else
                {
                    constr = IniReadValue("UindexWeb", "ConnStr");
                }
                BottomStatusBar.Panels[1].Text = "正在建立索引，请等待...";
                writer = new IndexWriter(OutputDir.Text + "\\UindexWeb", new StandardAnalyzer(), true);
                status.Text = "";
                status.AppendText("输出目录：\r\n" + OutputDir.Text + "\\UindexWeb\r\n启动索引线程...\r\n");
                if (UseCSW.Checked) { status.AppendText("启用CSW中文分词。\r\n"); }
                else { status.AppendText("跳过分词。\r\n"); }
                writer.SetUseCompoundFile(true);
                //-------------------------------------------------------------------
                //创建Lucene全文检索写入器
                //-------------------------------------------------------------------
                Thread me = new Thread(new ThreadStart(IndexThread));
                //-------------------------------------------------------------------
                // 创建新线程
                //-------------------------------------------------------------------
                myfreshui = new efreshui(this.freshui);
                myComplete = new efreshui(this.ThreadComplete);
                me.Start();
                SetUiEnable(false);
            }
		}
        private void SetUiEnable(bool en) {
            BtnSelectConfig.Enabled = en;
            BtnNext.Enabled = en;
            ConfigFile.Enabled = en;
            OutputDir.Enabled = en;
            UseLucene.Enabled = en;
            UseCSW.Enabled = en;
            SelectOutDir.Enabled = en;
        }
		private string GetPath(string filename){
			string file=Path.GetFileName(filename);
			return filename.Substring(0,(filename.Length-file.Length)-1);
		}
		private void mainform_Closing(object sender, System.ComponentModel.CancelEventArgs e)
		{
			terminated=true;
        }

        private void GoBack_Click(object sender, EventArgs e)
        {
            if(MainTabs.SelectedIndex > 0)
               MainTabs.SelectedIndex--;
        }

        private void SelectOutDir_Click(object sender, EventArgs e)
        {
            if (SelectOutputDir.ShowDialog() == DialogResult.OK)
                OutputDir.Text = SelectOutputDir.SelectedPath;
        }

        private void MainTabs_SelectedIndexChanged(object sender, EventArgs e)
        {
            //标签切换时的提示
            switch (MainTabs.SelectedIndex) {
                case 0: BottomStatusBar.Panels[1].Text = "指定配置文件。"; break;
                case 1: BottomStatusBar.Panels[1].Text = "选择分词组件。"; break;
                case 2: BottomStatusBar.Panels[1].Text = "设置全文索引目录输出位置。"; break;
                default: break;
            }
        }

        private void UseCSW_CheckedChanged(object sender, EventArgs e)
        {
            if (!needtrycsw && UseCSW.Checked)
            {
                MessageBox.Show("请从CSW主页下载基于C接口的CSW中文分词组件，并解压至本程序相同目录。\n\nCSW主页：www.vgoogle.net。", "CSW未找到",
                        MessageBoxButtons.OK, MessageBoxIcon.Question);
                UseCSW.Checked = false;
                UseLucene.Checked = true;
            }
        }
	}
}
