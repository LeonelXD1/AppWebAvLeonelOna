using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        private string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        /// <summary>
        /// True only when the user logged in the session is an administrator.
        /// </summary>
        public bool IsAdmin
        {
            get
            {
                Entities.User user = Session[Util.Constants.USER] as Entities.User;
                if (user == null)
                {
                    return false;
                }
                return user.UserType == Util.Constants.ID_USER_ADMIN;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Entities.User user = Session[Util.Constants.USER] as Entities.User;
            if (user == null)
            {
                Response.Redirect("Login.aspx", true);
                return;
            }

            // The administration panel is rendered only for administrators.
            pnlAdmin.Visible = IsAdmin;

            if (!Page.IsPostBack)
            {
                LoadUserInfo(user);
                litNowPlaying.Text = "<span class=\"now-title is-empty\">Ninguna canción seleccionada</span>";
                LoadSongs();
            }
        }

        #region Presentation

        private void LoadUserInfo(Entities.User user)
        {
            string userName = user.UserName == null ? string.Empty : user.UserName;
            litUserName.Text = System.Web.HttpUtility.HtmlEncode(userName);
            litUserInitial.Text = userName.Length > 0 ? System.Web.HttpUtility.HtmlEncode(userName.Substring(0, 1)) : "?";
            litRole.Text = IsAdmin ? "<span class=\"role-tag\">Admin</span>" : string.Empty;
        }

        private void LoadSongs()
        {
            DataTable dtSongs = GetSongs();
            gvSongs.DataSource = dtSongs;
            gvSongs.DataBind();
            litSongCount.Text = dtSongs.Rows.Count.ToString();
        }

        /// <summary>
        /// Reads the songs and adds a formatted column for PLAYS, because the column is NULLable in the database.
        /// </summary>
        private DataTable GetSongs()
        {
            DataTable dtSongs = new BLL.Song(strConnString).Read();
            if (!dtSongs.Columns.Contains("PLAYS_TEXT"))
            {
                dtSongs.Columns.Add("PLAYS_TEXT", typeof(string));
            }
            foreach (DataRow row in dtSongs.Rows)
            {
                int plays = (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);
                row["PLAYS_TEXT"] = plays.ToString();
            }
            return dtSongs;
        }

        private DataRow FindSong(DataTable dtSongs, int idSong)
        {
            foreach (DataRow row in dtSongs.Rows)
            {
                if (Convert.ToInt32(row["ID_SONG"]) == idSong)
                {
                    return row;
                }
            }
            return null;
        }

        private void ShowMessage(string message, string kind)
        {
            lblMessage.CssClass = "msg " + kind;
            lblMessage.Text = message;
        }

        private void ClearMessage()
        {
            lblMessage.CssClass = "msg";
            lblMessage.Text = string.Empty;
        }

        private void ResetForm()
        {
            hfSongID.Value = "0";
            txtSongName.Text = string.Empty;
            btnSave.Text = "Agregar canción";
            btnCancel.Visible = false;
        }

        #endregion

        #region GridView events

        protected void gvSongs_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            // Normal users must not see the edit/delete column (header and data rows only).
            if (!IsAdmin && (e.Row.RowType == DataControlRowType.Header || e.Row.RowType == DataControlRowType.DataRow))
            {
                e.Row.Cells[e.Row.Cells.Count - 1].Visible = false;
            }
        }

        protected void gvSongs_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            int idSong;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out idSong))
            {
                return;
            }

            if (e.CommandName == "PlaySong")
            {
                PlaySong(idSong);
                return;
            }

            // Every other command is reserved to the administrator.
            if (!IsAdmin)
            {
                return;
            }

            if (e.CommandName == "EditSong")
            {
                LoadSongForEdit(idSong);
            }
            else if (e.CommandName == "DeleteSong")
            {
                DeleteSong(idSong);
            }
        }

        #endregion

        #region Player

        private void PlaySong(int idSong)
        {
            DataRow row = FindSong(new BLL.Song(strConnString).Read(), idSong);
            if (row == null)
            {
                return;
            }

            string songName = Convert.ToString(row["SONG_NAME"]);
            string songPath = Convert.ToString(row["SONG_PATH"]);

            litNowPlaying.Text = "<span class=\"now-title\">" + System.Web.HttpUtility.HtmlEncode(songName) + "</span>";
            litPlayer.Text = "<audio controls=\"controls\" autoplay=\"autoplay\" preload=\"none\" src=\"" +
                System.Web.HttpUtility.HtmlAttributeEncode(ResolveUrl(songPath)) + "\"></audio>";

            new BLL.Song(strConnString).IncreasePlays(idSong);
            LoadSongs();
        }

        #endregion

        #region CRUD (administrator only)

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!IsAdmin)
            {
                return;
            }

            string songName = txtSongName.Text.Trim();
            if (songName == string.Empty)
            {
                ShowMessage("El nombre de la canción es obligatorio.", "err");
                return;
            }

            int idSong;
            int.TryParse(hfSongID.Value, out idSong);

            if (idSong == 0)
            {
                InsertSong(songName);
            }
            else
            {
                UpdateSong(idSong, songName);
            }
        }

        private void InsertSong(string songName)
        {
            if (!fupSong.HasFile)
            {
                ShowMessage("Selecciona un archivo MP3 para agregar la canción.", "err");
                return;
            }

            Entities.Song song = new Entities.Song();
            song.SongName = songName;
            song.Plays = 0;

            string messageValidations = new BLL.Song(strConnString).ValidationsDuplicated(song);
            if (messageValidations != string.Empty)
            {
                ShowMessage(messageValidations, "err");
                return;
            }

            string strSongFolder = ConfigurationManager.AppSettings["songFolderPath"];
            string newFileName = songName.Replace(" ", string.Empty);

            messageValidations = new FileManagement().SaveSongOnServer(fupSong, strSongFolder, newFileName);
            if (messageValidations != string.Empty)
            {
                ShowMessage(messageValidations, "err");
                return;
            }

            song.SongPath = strSongFolder + newFileName + System.IO.Path.GetExtension(fupSong.FileName).ToLower();
            new BLL.Song(strConnString).Save(song);

            ResetForm();
            LoadSongs();
            ShowMessage("Canción agregada correctamente.", "ok");
        }

        private void UpdateSong(int idSong, string songName)
        {
            DataRow row = FindSong(new BLL.Song(strConnString).Read(), idSong);
            if (row == null)
            {
                ShowMessage("La canción ya no existe en la biblioteca.", "err");
                LoadSongs();
                return;
            }

            string songPath = Convert.ToString(row["SONG_PATH"]);
            int plays = (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);

            if (fupSong.HasFile)
            {
                string strSongFolder = ConfigurationManager.AppSettings["songFolderPath"];
                string newFileName = songName.Replace(" ", string.Empty);

                string messageValidations = new FileManagement().SaveSongOnServer(fupSong, strSongFolder, newFileName);
                if (messageValidations != string.Empty)
                {
                    ShowMessage(messageValidations, "err");
                    return;
                }
                songPath = strSongFolder + newFileName + System.IO.Path.GetExtension(fupSong.FileName).ToLower();
            }

            Entities.Song song = new Entities.Song(idSong, songName, songPath, plays);
            new BLL.Song(strConnString).Update(song);

            ResetForm();
            LoadSongs();
            ShowMessage("Canción actualizada correctamente.", "ok");
        }

        private void LoadSongForEdit(int idSong)
        {
            DataRow row = FindSong(new BLL.Song(strConnString).Read(), idSong);
            if (row == null)
            {
                ShowMessage("La canción ya no existe en la biblioteca.", "err");
                return;
            }

            hfSongID.Value = idSong.ToString();
            txtSongName.Text = Convert.ToString(row["SONG_NAME"]);
            btnSave.Text = "Actualizar canción";
            btnCancel.Visible = true;
            ShowMessage("Editando «" + System.Web.HttpUtility.HtmlEncode(Convert.ToString(row["SONG_NAME"])) +
                "». Si no eliges un archivo nuevo, se conserva el MP3 actual.", "info");
        }

        private void DeleteSong(int idSong)
        {
            try
            {
                new BLL.Song(strConnString).Delete(idSong);
                ResetForm();
                LoadSongs();
                ShowMessage("Canción eliminada de la biblioteca.", "ok");
            }
            catch (SqlException)
            {
                // TBL_SONG is referenced by TBL_TRACKLIST, TBL_PLAYER and TBL_PLAYLIST_SONG.
                ShowMessage("No se puede eliminar: la canción está asociada a una playlist, un artista o el reproductor.", "err");
            }
        }

        protected void btnCancel_Click(object sender, EventArgs e)
        {
            ResetForm();
            ClearMessage();
        }

        #endregion
    }
}
