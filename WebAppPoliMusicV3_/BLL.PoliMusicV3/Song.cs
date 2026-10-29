using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.PoliMusicV3
{
    public class Song
    {
        private string strConnectionString;
        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public int Save(string songName, string songPath, int plays)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Save(songName, songPath, plays);
        }

        public DataTable Read()
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Read();
        }

        public int Update(int idSong, string songName, string songPath, int plays)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Update(idSong, songName, songPath, plays);
        }

        public int Delete(int id)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Delete(id);
        }

        public int CheckExistSong(string songName)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).CheckExistSong(songName);
        }

        public int IncreasePlays(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).IncreasePlays(idSong);
        }

        public string ValidationsDuplicated(string songName)
        {
            int returnValue = CheckExistSong(songName);
            if (returnValue != 0)
            {
                return "Song already registered!";
            }
            return string.Empty;
        }
    }

}
