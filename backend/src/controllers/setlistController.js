import Setlist from "../models/Setlist.js";
import SetlistSong from "../models/SetlistSong.js";
import AudioJob from "../models/AudioJob.js";

export const createSetlist = async (req, res) => {
  try {
    const { title } = req.body;
    const setlist = await Setlist.create({
      title,
      userId: req.user.id,
    });
    res.status(201).json(setlist);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getMySetlists = async (req, res) => {
  try {
    const setlists = await Setlist.findAll({
      where: { userId: req.user.id },
      include: [
        {
          model: AudioJob,
          as: "songs",
          attributes: ["id"],
          through: { attributes: ["order"] },
        },
      ],
    });

    // Format output to match app expectations and sort songs by order
    const formatted = setlists.map((s) => {
      const sortedSongs = [...s.songs].sort((a, b) => a.SetlistSong.order - b.SetlistSong.order);
      return {
        id: s.id,
        title: s.title,
        songIds: sortedSongs.map((song) => song.id),
      };
    });

    res.json(formatted);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getSetlistDetail = async (req, res) => {
  try {
    const setlist = await Setlist.findOne({
      where: { id: req.params.id, userId: req.user.id },
      include: [
        {
          model: AudioJob,
          as: "songs",
          through: { attributes: ["order"] },
        },
      ],
    });

    if (!setlist) {
      return res.status(404).json({ message: "Setlist not found" });
    }

    // Sort songs manually
    const plainSetlist = setlist.get({ clone: true });
    plainSetlist.songs.sort((a, b) => a.SetlistSong.order - b.SetlistSong.order);

    res.json(plainSetlist);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const deleteSetlist = async (req, res) => {
  try {
    const setlist = await Setlist.findOne({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!setlist) {
      return res.status(404).json({ message: "Setlist not found" });
    }

    await SetlistSong.destroy({ where: { setlistId: setlist.id } });
    await setlist.destroy();

    res.json({ message: "Setlist deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const addSongToSetlist = async (req, res) => {
  try {
    const { setlistId, audioJobId } = req.body;

    const setlist = await Setlist.findOne({
      where: { id: setlistId, userId: req.user.id },
    });

    if (!setlist) {
      return res.status(404).json({ message: "Setlist not found" });
    }

    const exists = await SetlistSong.findOne({
      where: { setlistId, audioJobId },
    });

    if (exists) {
      return res.status(400).json({ message: "Song already in setlist" });
    }

    const maxOrder = await SetlistSong.max('order', { where: { setlistId } });
    const nextOrder = (maxOrder !== null && maxOrder !== undefined) ? maxOrder + 1 : 0;

    await SetlistSong.create({ setlistId, audioJobId, order: nextOrder });
    res.status(201).json({ message: "Song added to setlist" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const removeSongFromSetlist = async (req, res) => {
  try {
    const { setlistId, songId } = req.params;

    const setlist = await Setlist.findOne({
      where: { id: setlistId, userId: req.user.id },
    });

    if (!setlist) {
      return res.status(404).json({ message: "Setlist not found" });
    }

    await SetlistSong.destroy({
      where: { setlistId, audioJobId: songId },
    });

    res.json({ message: "Song removed from setlist" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const reorderSetlist = async (req, res) => {
  try {
    const { setlistId, songIds } = req.body;

    const setlist = await Setlist.findOne({
      where: { id: setlistId, userId: req.user.id }
    });

    if (!setlist) {
      return res.status(404).json({ message: 'Setlist not found' });
    }

    const updates = songIds.map((id, index) => 
      SetlistSong.update({ order: index }, { where: { setlistId, audioJobId: id } })
    );
    await Promise.all(updates);

    res.json({ message: 'Setlist reordered' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
