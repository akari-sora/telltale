import android.os.Bundle;
import com.android.uiautomator.core.UiObjectNotFoundException;
import com.android.uiautomator.core.UiScrollable;
import com.android.uiautomator.core.UiSelector;
import com.android.uiautomator.testrunner.UiAutomatorTestCase;

/** One-shot UiAutomator scrollIntoView for D05 Settings → Service Recipes. */
public class D05Scroll extends UiAutomatorTestCase {
    public void testScroll() {
        String needle = "Service Recipes";
        try {
            Bundle extras = getParams();
            if (extras != null) {
                String requested = extras.getString("needle");
                if (requested != null && requested.length() > 0) {
                    needle = requested;
                }
            }
        } catch (Throwable ignored) {
        }
        try {
            UiScrollable list = new UiScrollable(new UiSelector().scrollable(true));
            list.setAsVerticalList();
            list.setMaxSearchSwipes(24);
            boolean shown = false;
            try {
                shown = list.scrollIntoView(new UiSelector().descriptionContains(needle));
            } catch (UiObjectNotFoundException ignored) {
            }
            if (!shown) {
                try {
                    list.scrollIntoView(new UiSelector().textContains(needle));
                } catch (UiObjectNotFoundException ignored) {
                }
            }
        } catch (Throwable ignored) {
        }
    }
}
