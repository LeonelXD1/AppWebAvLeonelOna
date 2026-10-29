using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : System.Web.UI.Page
    {
        private string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        /// <summary>
        /// True only when the user stored in the session is an administrator.
        /// </summary>
        public bool IsAdmin
        {
            get
            {
                EntityLayer.PoliMusicV3.User user = Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User;
                if (user == null)
                {
                    return false;
                }
                return user.UserType == EntityLayer.PoliMusicV3.Util.Constants.ID_USER_ADMIN;
            }
        }

        /// <summary>
        /// Application folder where the MP3 files are stored.
        /// </summary>
        private string SongFolder
        {
            get
            {
                string folder = ConfigurationManager.AppSettings["songFolderPath"];
                if (string.IsNullOrEmpty(folder))
                {
                    return "~/SongFiles/";
                }
                // The configuration value may be a relative path ("../songFiles/"); the folder
                // must always live inside the application, so it is normalised to an app path.
                folder = folder.Replace("../", string.Empty).Replace("..\\", string.Empty);
                if (!folder.StartsWith("~/"))
                {
                    folder = "~/" + folder.TrimStart('/', '\\');
                }
                return folder;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            EntityLayer.PoliMusicV3.User user = Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User;
            if (user == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            // The administration panel is rendered only for administrators.
            pnlAdmin.Visible = IsAdmin;

            if (!Page.IsPostBack)
            {
                LoadUserInfo(user);
                ResetPlayer();
                LoadSongs();
            }
        }

        #region Presentation

        private void LoadUserInfo(EntityLayer.PoliMusicV3.User user)
        {
            string userName = user.UserName == null ? string.Empty : user.UserName;
            litUserName.Text = HttpUtility.HtmlEncode(userName);
            litUserInitial.Text = userName.Length > 0 ? HttpUtility.HtmlEncode(userName.Substring(0, 1)) : "?";
            litRole.Text = IsAdmin ? "<span class=\"role-tag\">Admin</span>" : string.Empty;
        }

        private void LoadSongs()
        {
            DataTable dtSongs = GetSongs();
            gvSongs.DataSource = dtSongs;
            gvSongs.DataBind();

            int totalPlays = 0;
            foreach (DataRow row in dtSongs.Rows)
            {
                totalPlays += (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);
            }

            litHeroMeta.Text = string.Format("{0} {1} · {2} reproducciones",
                dtSongs.Rows.Count,
                dtSongs.Rows.Count == 1 ? "canción" : "canciones",
                totalPlays);
        }

        /// <summary>
        /// Reads the songs and adds a formatted column for PLAYS, because the column is NULLable in the database.
        /// </summary>
        private DataTable GetSongs()
        {
            DataTable dtSongs = new BLL.PoliMusicV3.Song(strConnString).Read();
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

        /// <summary>
        /// Converts a stored SONG_PATH into a URL that the browser can request.
        /// </summary>
        private string NormalizeSongPath(string songPath)
        {
            if (string.IsNullOrEmpty(songPath))
            {
                return string.Empty;
            }
            songPath = songPath.Replace("../", string.Empty).Replace("..\\", string.Empty);
            if (!songPath.StartsWith("~/") && !songPath.StartsWith("/"))
            {
                songPath = "~/" + songPath.TrimStart('/', '\\');
            }
            return songPath;
        }

        private void ResetPlayer()
        {
            hfNowPlaying.Value = "0";
            litNowPlaying.Text = "<span class=\"now-title is-empty\">Ninguna canción seleccionada</span>";
            litPlayer.Text = "<div class=\"player-empty\">Elige una canción de la lista para escucharla.</div>";
            litPlayerMeta.Text = string.Empty;
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
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                DataRowView rowView = e.Row.DataItem as DataRowView;
                e.Row.CssClass = "track-row";

                // The row of the song that is being played gets the equalizer.
                int idSong;
                if (rowView != null && int.TryParse(hfNowPlaying.Value, out idSong) &&
                    Convert.ToInt32(rowView["ID_SONG"]) == idSong)
                {
                    e.Row.CssClass = "track-row is-playing";
                }

                // Normal users must not see the edit/delete column.
                if (!IsAdmin)
                {
                    e.Row.Cells[e.Row.Cells.Count - 1].Visible = false;
                }
            }
            else if (e.Row.RowType == DataControlRowType.Header && !IsAdmin)
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
            DataRow row = FindSong(GetSongs(), idSong);
            if (row == null)
            {
                ShowMessage("La canción ya no existe en la biblioteca.", "err");
                LoadSongs();
                return;
            }

            string songName = Convert.ToString(row["SONG_NAME"]);
            string songPath = Convert.ToString(row["SONG_PATH"]);
            int plays = (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);

            hfNowPlaying.Value = idSong.ToString();
            litNowPlaying.Text = "<span class=\"now-title\">" + HttpUtility.HtmlEncode(songName) + "</span>";
            litPlayer.Text = "<audio controls=\"controls\" autoplay=\"autoplay\" preload=\"none\" src=\"" +
                HttpUtility.HtmlAttributeEncode(ResolveUrl(NormalizeSongPath(songPath))) + "\"></audio>";
            litPlayerMeta.Text = "<div class=\"player-stat\"><strong>" + (plays + 1) + "</strong> reproducciones</div>";

            try
            {
                new BLL.PoliMusicV3.Song(strConnString).IncreasePlays(idSong);
            }
            catch (SqlException)
            {
                // The song is played even if the counter could not be updated.
            }

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

            string messageValidations = new BLL.PoliMusicV3.Song(strConnString).ValidationsDuplicated(songName);
            if (messageValidations != string.Empty)
            {
                ShowMessage(messageValidations, "err");
                return;
            }

            string strSongFolder = SongFolder;
            string newFileName = BuildFileName(songName);

            messageValidations = new FileManagement().SaveSongOnServer(fupSong, strSongFolder, newFileName);
            if (messageValidations != string.Empty)
            {
                ShowMessage(messageValidations, "err");
                return;
            }

            string songPath = strSongFolder + newFileName + Path.GetExtension(fupSong.FileName).ToLower();
            new BLL.PoliMusicV3.Song(strConnString).Save(songName, songPath, 0);

            ResetForm();
            LoadSongs();
            ShowMessage("Canción agregada correctamente.", "ok");
        }

        private void UpdateSong(int idSong, string songName)
        {
            DataRow row = FindSong(GetSongs(), idSong);
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
                string strSongFolder = SongFolder;
                string newFileName = BuildFileName(songName);

                string messageValidations = new FileManagement().SaveSongOnServer(fupSong, strSongFolder, newFileName);
                if (messageValidations != string.Empty)
                {
                    ShowMessage(messageValidations, "err");
                    return;
                }
                songPath = strSongFolder + newFileName + Path.GetExtension(fupSong.FileName).ToLower();
            }

            new BLL.PoliMusicV3.Song(strConnString).Update(idSong, songName, songPath, plays);

            ResetForm();
            LoadSongs();
            ShowMessage("Canción actualizada correctamente.", "ok");
        }

        private void LoadSongForEdit(int idSong)
        {
            DataRow row = FindSong(GetSongs(), idSong);
            if (row == null)
            {
                ShowMessage("La canción ya no existe en la biblioteca.", "err");
                return;
            }

            hfSongID.Value = idSong.ToString();
            txtSongName.Text = Convert.ToString(row["SONG_NAME"]);
            btnSave.Text = "Actualizar canción";
            btnCancel.Visible = true;
            ShowMessage("Editando «" + HttpUtility.HtmlEncode(Convert.ToString(row["SONG_NAME"])) +
                "». Si no eliges un archivo nuevo, se conserva el MP3 actual.", "info");
        }

        private void DeleteSong(int idSong)
        {
            try
            {
                new BLL.PoliMusicV3.Song(strConnString).Delete(idSong);

                if (hfNowPlaying.Value == idSong.ToString())
                {
                    ResetPlayer();
                }

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

        /// <summary>
        /// Builds a safe file name from the song name (no spaces, no invalid characters).
        /// </summary>
        private static string BuildFileName(string songName)
        {
            string fileName = songName.Trim();
            foreach (char invalid in Path.GetInvalidFileNameChars())
            {
                fileName = fileName.Replace(invalid.ToString(), string.Empty);
            }
            fileName = fileName.Replace(" ", string.Empty);
            if (fileName == string.Empty)
            {
                fileName = "song" + DateTime.Now.Ticks;
            }
            return fileName;
        }

        #endregion
    }
}
