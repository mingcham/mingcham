/*
  UindexWeb ASP.Net DEMO Application
---------------------------------------
  这个.Net程序演示了如何使用Lucene结合
ASP.Net来将蜘蛛搜索到的数据展示给用户,
使用这个demo需要安装IIS和.Net,然后把这
个目录复制到asp.net目录,就可以工作了.

              时间:14:31 2006-10-28
              作者:Uindex
---------------------------------------
Some Copyright NOT Reserved!
Index Powered by Lucene.Net
---------------------------------------
*/

using System;
using System.Data;
using System.Data.OleDb;
using System.Text.RegularExpressions;
using Lucene.Net.Analysis.Standard;
using Lucene.Net.Documents;
using Lucene.Net.QueryParsers;
using Lucene.Net.Search;
using System.Configuration;

namespace UindexWeb
{
	/// <summary>
	/// Summary description for WebForm1.
	/// </summary>
	public class Search : System.Web.UI.Page
	{
		/// <summary>
		/// Search results.
		/// </summary>
		protected DataTable Results = new DataTable();

		/// <summary>
		/// First item on page (index format).
		/// </summary>
		private int startAt;

		/// <summary>
		/// First item on page (user format).
		/// </summary>
		private int fromItem;

		/// <summary>
		/// Last item on page (user format).
		/// </summary>
		private int toItem;

		/// <summary>
		/// Total items returned by search.
		/// </summary>
		private int total;

		/// <summary>
		/// Time it took to make the search.
		/// </summary>
		private TimeSpan duration;

		/// <summary>
		/// How many items can be showed on one page.
		/// </summary>
		private readonly int maxResults = 10;

        protected System.Web.UI.WebControls.TextBox TextBoxQuery;
		protected System.Web.UI.WebControls.Repeater Repeater1;
		protected System.Web.UI.WebControls.Label LabelSummary;
		protected System.Web.UI.WebControls.Repeater Repeater2;
		protected System.Web.UI.WebControls.Image Image1;
		protected System.Web.UI.WebControls.Button ButtonSearch;

		private void Page_Load(object sender, System.EventArgs e)
		{
			try{
			Page.RegisterHiddenField("__EVENTTARGET", "ButtonSearch");}catch{}
			if (!IsPostBack)
			{
				if (this.Query != null)
				{
                    TextBoxQuery.Text = this.Query;
                    search();
					DataBind();
				}
			}
		}

		#region Web Form Designer generated code
		override protected void OnInit(EventArgs e)
		{
			//
			// CODEGEN: This call is required by the ASP.NET Web Form Designer.
			//
			InitializeComponent();
			base.OnInit(e);
		}

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.ButtonSearch.Click += new System.EventHandler(this.ButtonSearch_Click);
			this.Load += new System.EventHandler(this.Page_Load);

		}
		#endregion

		/// <summary>
		/// Does the search and stores the information about the results.
		/// </summary>
		private void search()
		{
			try{
			DateTime start = DateTime.Now;
			// index is placed in "index" subdirectory
			string indexDirectory = Server.MapPath("UindexWeb");
			IndexSearcher searcher = new IndexSearcher(indexDirectory);
			// parse the query, "text" is the default field to search
			Query query = MultiFieldQueryParser.Parse(this.Query,new String[]{"iTitle","iContent"}, new StandardAnalyzer());
            // create the result DataTable
			this.Results.Columns.Add("WPTitle", typeof(string));
			this.Results.Columns.Add("WPContent", typeof(string));
			this.Results.Columns.Add("WPUrl", typeof(string));
			// search
			Hits hits = searcher.Search(query);
			this.total = hits.Length();
			// initialize startAt
			this.startAt = initStartAt();
			// how many items we should show - less than defined at the end of the results
			int resultsCount = smallerOf (total, this.maxResults + this.startAt);
			for (int i = startAt; i < resultsCount; i++)
			{
				// get the document from index
				Document doc = hits.Doc(i);
				DataRow row = this.Results.NewRow();
				//关键字高亮,精简显示内容
				string content=doc.Get("WPContent");
				int pos=content.IndexOf(this.Query);
				int posA=0,posB=content.Length;
				int halflen=55;
				if(!(pos-halflen<0)){posA=pos-halflen;}
				if(!(pos+halflen>posB)){posB=pos+halflen;}
				content=content.Substring(posA,(posB-posA));
				content=content.Replace(this.Query,"<font color=red>"+this.Query+"</font>");
				//获取基本网页信息
				if(doc.Get("WPTitle").Length<2)
				{
                    if (doc.Get("WPContent").Length > 20)
					{
                        row["WPTitle"] = doc.Get("WPContent").Substring(0, 20)+"...";
                    }
					else{
                        row["WPTitle"] = doc.Get("WPContent");
                    }
					}
				else{
				    row["WPTitle"]       = doc.Get("WPTitle");
                }
				row["WPContent"]     = content;
				row["WPUrl"]        = doc.Get("WPUrl");
				this.Results.Rows.Add(row);
			}
			searcher.Close();
			// result information
			this.duration = DateTime.Now - start;
			this.fromItem = startAt + 1;
			this.toItem = smallerOf(startAt + maxResults, total);}
			catch(Exception e){Response.Write("<script language=javascript>alert(\""+e.Message+"\");</script>");
			}
		}
		/// <summary>
		/// Returns the smaller value of parameters.
		/// </summary>
		/// <param name="first"></param>
		/// <param name="second"></param>
		/// <returns></returns>
		private int smallerOf(int first, int second)
		{
			return first < second ? first : second;
		}

		/// <summary>
		/// Page links. DataTable might be overhead but there used to be more fields in previous version so I'm keeping it for now.
		/// </summary>
		protected DataTable Paging
		{
			get
			{
				// pageNumber starts at 1
				int pageNumber = (startAt + maxResults - 1) / maxResults;
				DataTable dt = new DataTable();
				dt.Columns.Add("html", typeof(string));
				DataRow ar = dt.NewRow();
				ar["html"] = pagingItemHtml(startAt, pageNumber + 1, false);
				dt.Rows.Add(ar);
				int previousPagesCount = 5;
				for (int i = pageNumber - 1; i >= 0 && i >= pageNumber - previousPagesCount; i--)
				{
					int step = i - pageNumber;
					DataRow r = dt.NewRow();
					r["html"] = pagingItemHtml(startAt + (maxResults * step), i + 1, true);
					dt.Rows.InsertAt(r, 0);
				}
				int nextPagesCount = 5;
				for (int i = pageNumber + 1; i <= pageCount && i <= pageNumber + nextPagesCount; i++)
				{
					int step = i - pageNumber;
					DataRow r = dt.NewRow();
					r["html"] = pagingItemHtml(startAt + (maxResults * step), i + 1, true);
					dt.Rows.Add(r);
				}
				return dt;
			}
		}

		/// <summary>
		/// Prepares HTML of a paging item (bold number for current page, links for others).
		/// </summary>
		/// <param name="start"></param>
		/// <param name="number"></param>
		/// <param name="active"></param>
		/// <returns></returns>
		private string pagingItemHtml(int start, int number, bool active)
		{
			if (active)
                return "<a style=\"TEXT-DECORATION:none\" href=\"index.aspx?q=" + this.Query + "&start=" + start + "\">[" + number + "]</a>&nbsp;";
			else
                return number.ToString() + "&nbsp;";
		}

		/// <summary>
		/// Prepares the string with seach summary information.
		/// </summary>
		protected string Summary
		{
			get
			{
				if (total > 0)
					return "搜索 <b>" + this.Query + "</b> 结果如下, 共 <b>" + this.total + "</b> 当前 <b>" + this.fromItem + " - " + this.toItem + "</b>. 用时(" + this.duration.TotalSeconds.ToString("#0.###") + " 秒)";
				return "没有搜到 "+ this.Query;
			}
		}
		/// <summary>
		/// Return search query or null if not provided.
		/// </summary>
		public string Query
		{
			get
			{
				string query = this.Request.Params["q"];
				if (query == String.Empty)
					return null;
				return query;
			}
		}

		/// <summary>
		/// Initializes startAt value. Checks for bad values.
		/// </summary>
		/// <returns></returns>
		private int initStartAt()
		{
			try
			{
				int sa = Convert.ToInt32(this.Request.Params["start"]);

				// too small starting item, return first page
				if (sa < 0)
					return 0;

				// too big starting item, return last page
				if (sa >= total - 1)
				{
					return lastPageStartsAt;
				}

				return sa;
			}
			catch
			{
				return 0;
			}
		}

		/// <summary>
		/// How many pages are there in the results.
		/// </summary>
		private int pageCount
		{
			get
			{
				return (total - 1) / maxResults; // floor
			}
		}

		/// <summary>
		/// First item of the last page
		/// </summary>
		private int lastPageStartsAt
		{
			get
			{
				return pageCount * maxResults;
			}
		}


		/// <summary>
		/// This should be replaced with a direct client-side get
		/// </summary>
		/// <param name="sender"></param>
		/// <param name="e"></param>
		private void ButtonSearch_Click(object sender, System.EventArgs e)
		{
            this.Response.Redirect("index.aspx?q=" + this.TextBoxQuery.Text);
		}

		/// <summary>
		/// Very simple, inefficient, and memory consuming HTML parser. Take a look at Demo/HtmlParser in DotLucene package for a better HTML parser.
		/// </summary>
		/// <param name="html"></param>
		/// <returns></returns>
		private string parseHtml(string html)
		{
			string temp = Regex.Replace(html, "<[^>]*>", "");
			return temp.Replace("&nbsp;", " ");
		}

	}
}
