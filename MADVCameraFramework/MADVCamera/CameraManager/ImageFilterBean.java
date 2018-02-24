package com.madv360.madv.model.bean;

import com.madv360.glrenderer.GLFilterCache;
import com.madv360.madv.R;

import java.util.ArrayList;

/**
 * Created by qiudong on 16/6/17.
 */
public class ImageFilterBean {

    public int uuid;

    public String name;

    public String enName;

    public String iconPNGUri1;

    public String iconPNGUri2;

    public ImageFilterBean() {

    }

    public ImageFilterBean(int uuid, String name, String enName, String uri1, String uri2) {
        this.uuid = uuid;
        this.name = name;
        this.enName = enName;
        this.iconPNGUri1 = uri1;
        this.iconPNGUri2 = uri2;
    }

    private static ArrayList<ImageFilterBean> ImageFilters = null;

    public static final synchronized ArrayList<ImageFilterBean> allImageFilters() {
        if (null == ImageFilters) {
            ImageFilters = new ArrayList<>();
            ImageFilters.add(new ImageFilterBean(GLFilterCache.GLFilterNone, "原图", "Original"
                    , "res://com.madv360.madv/" + R.drawable.nothing_1
                    , "res://com.madv360.madv/" + R.drawable.nothing_2));
            ImageFilters.add(new ImageFilterBean(GLFilterCache.GLFilterBilateralID, "磨皮", "Bilateral"
                    , "res://com.madv360.madv/" + R.drawable.exfoliating_1
                    , "res://com.madv360.madv/" + R.drawable.exfoliating_2));
            ImageFilters.add(new ImageFilterBean(GLFilterCache.GLFilterSepiaToneID, "流年", "Sepia Tone"
                    , "res://com.madv360.madv/" + R.drawable.past_1
                    , "res://com.madv360.madv/" + R.drawable.past_2));
            ImageFilters.add(new ImageFilterBean(GLFilterCache.GLFilterAmatorkaID, "青春", "Amatorka"
                    , "res://com.madv360.madv/" + R.drawable.young_1
                    , "res://com.madv360.madv/" + R.drawable.young_2));
            ImageFilters.add(new ImageFilterBean(GLFilterCache.GLFilterMissEtikateID, "海韵", "Miss Etikate"
                    , "res://com.madv360.madv/" + R.drawable.sea_1
                    , "res://com.madv360.madv/" + R.drawable.sea_2));
            ImageFilters.add(new ImageFilterBean(GLFilterCache.GLFilterInverseColorID, "胶片", "Color Inverse"
                    , "res://com.madv360.madv/" + R.drawable.film_1
                    , "res://com.madv360.madv/" + R.drawable.film_2));
        }
        return ImageFilters;
    }

    public static final ImageFilterBean findImageFilterByID(int uuid) {
        ArrayList<ImageFilterBean> filters = allImageFilters();
        for (ImageFilterBean filter : filters) {
            if (filter.uuid == uuid) {
                return filter;
            }
        }
        return null;
    }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof ImageFilterBean))
            return false;

        ImageFilterBean other = (ImageFilterBean) o;
        return (other.uuid == this.uuid);
    }

    @Override
    public int hashCode() {
        return uuid;
    }
}
